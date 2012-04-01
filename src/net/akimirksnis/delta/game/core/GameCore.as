package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.SkyBox;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.GeoSphere;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.Geometry;
	
	import flash.display.Stage3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.cameras.DebugFRCamera;
	import net.akimirksnis.delta.game.cameras.FPSCamera;
	import net.akimirksnis.delta.game.cameras.IsometricCamera;
	import net.akimirksnis.delta.game.controllers.*;
	import net.akimirksnis.delta.game.controllers.interfaces.*;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.statics.Teapot;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.units.Walker2;
	import net.akimirksnis.delta.game.entities.weapons.SMG;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	import net.akimirksnis.delta.game.gui.controllers.LevelSelectionOverlayController;
	import net.akimirksnis.delta.game.gui.controllers.PreloaderOverlayController;
	import net.akimirksnis.delta.game.library.Library;
	import net.akimirksnis.delta.game.loaders.CoreLoader;
	import net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent;
	import net.akimirksnis.delta.game.loaders.parsers.ModelParser;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;

	public class GameCore
	{
		// Turn debug mode on/off
		public static const DEBUG_MODE_ON:Boolean = true;		
		// Wireframe element colors
		public static const MAP_MESH_COLOR:uint = 0x008909;
		public static const MAP_TERRAIN_COLOR:uint = 0x666666;
		public static const MAP_DEFAULT_COLOR:uint = 0xFF0000;
		public static const COLLISION_MESH_WIREFRAME_COLOR:uint = 0x00FF00;		
		// Unit in control		
		private var _unit:Unit;		
		// Renderer
		private var renderer3D:Renderer3D;		
		// Collections		
		private var entities:Vector.<Entity> = new Vector.<Entity>();
		private var _units:Vector.<Unit> = new Vector.<Unit>();
		private var loopCallbacksPre:Vector.<Function> = new Vector.<Function>();
		private var mapWireframes:Vector.<WireFrame> = new Vector.<WireFrame>();
		private var specialWireframes:Vector.<WireFrame> = new Vector.<WireFrame>();		
		// Controllers		
		private var _guiController:GuiController;
		// Camera controller currently in use
		private var _cameraController:ICameraController;
		// Standart unit/camera controller
		private var _fpsController:ICameraController;
		// Debug free roam controller
		private var _freeRoamController:ICameraController;		
		// Pathfinding, collision, terrain meshes		
		private var mapRunning:Boolean;
		private var _terrainMesh:Mesh;
		private var _collisionMesh:Mesh;
		
		// NEW
		private var coreLoader:CoreLoader
		
		/**
		 * Class constructor.
		 */
		public function GameCore()
		{			
			super();
			
			// Set global reference
			Globals.gameCore = this;
			
			// Set global debug mode indicator
			Globals.debugMode = DEBUG_MODE_ON;
			
			// Create Gui controller (must be created before all other controllers!)
			// This is because it handles all graphical 2D interface, including menus, preloaders and more..
			_guiController = GuiController.instance;
			_guiController.enabled = false;
			
			// Get new instance of the library
			Globals.library = Library.instance;
			
			// Request context3D and initialize 3D renderer
			Globals.stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
			Globals.stage3D.requestContext3D();
		}
		
		/**
		 * Fired after context3D is acquired.
		 * 
		 * @param e Event object.
		 */
		private function onContext3DCreated(e:Event):void
		{
			Globals.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
			
			// Paths to config XML files
			// 1. Assets file (currently the only config)
			var XMLPaths:Array = [
				Globals.LOCAL_ROOT + Globals.ASSETS_XML
			]

			// Load assets
			coreLoader = new CoreLoader(XMLPaths, Globals.library, PreloaderOverlayController(_guiController.getOverlayControllerByName("PreloaderOverlayController")));			
			coreLoader.addEventListener(CoreLoaderEvent.ASSETS_LOADED, onAssetsLoaded, false, 0, true);			
			coreLoader.loadAssets();
		}
		
		/**
		 * Fired after all assets are loaded.
		 * 
		 * @param e Event object.
		 */
		private function onAssetsLoaded(e:Event):void
		{	
			coreLoader.removeEventListener(CoreLoaderEvent.ASSETS_LOADED, onAssetsLoaded);
			
			// Create renderer
			renderer3D = new Renderer3D(Globals.stage3D);
			Globals.renderer = renderer3D;
			
			// Bring GUI to top
			guiController.bringToTop();
			guiController.enabled = true;
			
			// Load map
			coreLoader.addEventListener(CoreLoaderEvent.MAP_LOADED, onMapLoaded, false, 0, true);
			
			// Focus level selection overlay
			var lsoController:LevelSelectionOverlayController = _guiController.getOverlayControllerByName("LevelSelectionOverlayController") as LevelSelectionOverlayController;			
			lsoController.mapData = Library.instance.mapData;		
			lsoController.focus();
			
			//coreLoader.loadMap("crossfire");
		}
		
		/**
		 * Fired after map is loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapLoaded(e:Event):void
		{	
			coreLoader.removeEventListener(CoreLoaderEvent.ASSETS_LOADED, onMapLoaded, false);
		}
		
		/*---------------------------
		Base class event callbacks
		---------------------------*/
		
		/**
		 * Fired when map geometry is loaded. It is uncertain whether map materials are loaded at this time.
		 * @param e Event object.
		 */
		private function onMapGeometryLoaded(e:Event):void
		{
			//removeEventListener(CoreEvent.MAP_LOADED, onMapGeometryLoaded, false);
			
			// Set collision mesh
			//_collisionMesh = getObjectByName("collision_mesh_root") as Mesh;
			_collisionMesh = Globals.library.getObjectByName("terrain_root") as Mesh;
			renderer.addObject3D(_collisionMesh);
			
			// Set terrain mesh
			_terrainMesh = Globals.library.getObjectByName("terrain_root") as Mesh;
			renderer.addObject3D(_terrainMesh);
			
			_collisionMesh.x = collisionMesh.y = collisionMesh.z = 0;
			_terrainMesh.x = _terrainMesh.y = _terrainMesh.z = 0;
			
			// Handle debug mode
			if(DEBUG_MODE_ON)
			{
				// Generate wireframes for various map meshes
				generateWireframes();
				
				// Debug lights
				renderer.debugLights = true;
			}			
		}
		
		//testy
		public var ctents:Vector.<Entity> = new Vector.<Entity>();		
		// test embeds for skybox
		private var sb:SkyBox;
		[Embed(source="C:/Users/Varnius/Desktop/testsky/top.jpg")]
		static private const SBTop:Class;
		[Embed(source="C:/Users/Varnius/Desktop/testsky/bottom.jpg")]
		static private const SBBottom:Class;
		[Embed(source="C:/Users/Varnius/Desktop/testsky/front.jpg")]
		static private const SBFront:Class;
		[Embed(source="C:/Users/Varnius/Desktop/testsky/back.jpg")]
		static private const SBBack:Class;
		[Embed(source="C:/Users/Varnius/Desktop/testsky/left.jpg")]
		static private const SBLeft:Class;
		[Embed(source="C:/Users/Varnius/Desktop/testsky/right.jpg")]
		static private const SBRight:Class;
		
		/**
		 * Fired when map materials are loaded. Whole map is fully loaded when this event is fired.
		 * @param e Event object.
		 */
		private function onMapTexturesLoaded(e:Event):void
		{
			//removeEventListener(CoreEvent.MAP_TEXTURES_LOADED, onMapTexturesLoaded);			
			trace("[GameCore] Map geometry and textures loaded.");
			
			// SKYBOX
			
			// create skybox textures
			var topres:BitmapTextureResource = new BitmapTextureResource(new SBTop().bitmapData);
			var top:TextureMaterial = new TextureMaterial(topres);
			var bottomres:BitmapTextureResource = new BitmapTextureResource(new SBBottom().bitmapData);
			var bottom:TextureMaterial = new TextureMaterial(bottomres);
			var frontres:BitmapTextureResource = new BitmapTextureResource(new SBFront().bitmapData);
			var front:TextureMaterial = new TextureMaterial(frontres);
			var backres:BitmapTextureResource = new BitmapTextureResource(new SBBack().bitmapData);
			var back:TextureMaterial = new TextureMaterial(backres);
			var leftres:BitmapTextureResource = new BitmapTextureResource(new SBLeft().bitmapData);
			var left:TextureMaterial = new TextureMaterial(leftres);
			var rightres:BitmapTextureResource = new BitmapTextureResource(new SBRight().bitmapData);
			var right:TextureMaterial = new TextureMaterial(rightres);			
			renderer.uploadResource(topres);renderer.uploadResource(bottomres);renderer.uploadResource(frontres);renderer.uploadResource(backres);renderer.uploadResource(rightres);renderer.uploadResource(leftres);				
			sb = new SkyBox(150000,left,right,front,back,bottom,top,0.002);
			renderer.uploadResource(sb.geometry);
			renderer.addObject3D(sb);
			
			// AMBIENT LIGHTING
			
			// Create an ambient light
			var a:AmbientLight = new AmbientLight(0x111111);
			renderer.addLight(a);
			renderer.addLights(Globals.library.lights);
			Globals.library.lights.push(a);
			
			// CHARACTER			
			renderer.mainContainer.calculateBoundBox();
			var obj:Object3D = Globals.library.getObjectByName("func_spawn_a");
			
			_unit = new Walker2();
			renderer3D.addObject3D(_unit.model);
			/*_unit.model.x = obj.x;
			_unit.model.y = obj.y;
			_unit.model.z = obj.z;*/
			_unit.model.x = 0;
			_unit.model.y = 0;
			_unit.model.z = 500;
			_units.push(_unit);			
			ctents.push(_unit);
			
			var statice:Teapot = new Teapot();
			renderer.addObject3D(statice.model);
			statice.model.x = 1000;
			statice.model.z = 0;
			statice.showBoundBox = true;
			ctents.push(statice);		
			
			// Origin marker
			
			var pts:Vector.<Vector3D> = new Vector.<Vector3D>();
			pts.push(new Vector3D(0,0,0),new Vector3D(300,0,0));
			var originX:WireFrame = WireFrame.createLinesList(pts, 0xFF0000,1,2);
			pts = new Vector.<Vector3D>();
			pts.push(new Vector3D(0,0,0),new Vector3D(0,300,0));
			var originY:WireFrame = WireFrame.createLinesList(pts, 0x00FF00,1,2);
			pts = new Vector.<Vector3D>();
			pts.push(new Vector3D(0,0,0),new Vector3D(0,0,300));
			var originZ:WireFrame = WireFrame.createLinesList(pts, 0x0000FF,1,2);	
			
			renderer.addObject3D(originX, true);
			renderer.addObject3D(originY, true);
			renderer.addObject3D(originZ, true);
			
			// CONTROLLERS
					
			// Create standart unit.camera controller
			_fpsController = new FPSController(Globals.stage, new FPSCamera(), _unit);
			
			// Create free roam controler for debug purposes
			_freeRoamController = new FreeRoamController(Globals.stage, new DebugFRCamera());
			
			// Notify GuiController about camera controllers
			_guiController.fellowControllers.push(_fpsController, _freeRoamController);
			
			// Set current camera controller
			this.cameraController = _fpsController;
			

			// Map initialization is complete
			mapRunning = true;
			// Move GUI controller to the top
			_guiController.bringToTop();
			//Start main loop			
			startThinking();
		}
		
		/*---------------------------
		Main render loop
		---------------------------*/
		
		private function startThinking():void
		{
			// Start main loop
			Globals.stage.addEventListener(Event.ENTER_FRAME, think);
		}
		
		private function stopThinking():void
		{
			// Start main loop
			Globals.stage.removeEventListener(Event.ENTER_FRAME, think);
		}
		
		private function think(e:Event):void
		{
			trace("FRAMESTART--------------------------------------------");
			
			// Measure code execution time - start
			renderer.camera.startTimer();
			
			// Run loop callbacks (pre-render)
			for each(var callback:Function in loopCallbacksPre)
			{
				callback();
			}
			
			// Measure code execution time - stop
			renderer.camera.stopTimer();
			
			// Render frame
			renderer3D.renderFrame();
		}
		
		/**
		 * Adds function to execute before randering frame.
		 * 
		 * @param f Function to add.
		 */
		public function addLoopCallbackPre(f:Function):void
		{
			loopCallbacksPre.push(f);
		}
		
		/**
		 * Removes function from pre-frame rendering execution queue
		 * 
		 * @param f Function to remove.
		 */
		public function removeLoopCallbackPre(functionToRemove:Function):void
		{
			for each(var f:Function in loopCallbacksPre)
			{
				if(f == functionToRemove)
				{
					loopCallbacksPre.splice(loopCallbacksPre.indexOf(f), 1);
				}
			}
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		public function addEntity(e:Entity):void
		{
			entities.push(e);
			renderer3D.addObject3D(e.model);
		}
		
		public function removeEntity(entity:Entity):void
		{
			var index:int = -1;
			
			for each(var e:Entity in entities)
			{
				if(e == entity) index = entities.indexOf(e);
			}
			
			if(index != -1)
			{
				entities.splice(index, 1);
			} else {
				trace("[GameCore] Entity to remove not found.");
			}
			
			entity.dispose();
			renderer3D.removeObject3D(entity.model);
		}
		
		public function getEntityByName(name:String):Entity
		{
			var e:Entity;
			
			for each(var ent:Entity in entities)
			{
				if(ent.name == name) e = ent;
			}
			
			return e;
		}
		
		public function executeConsoleCommand(commandString:String):String
		{
			var command:String;
			var parsedValue:Number;
			var o:Object3D;
			var subs:Array;
			
			commandString = Utils.trim(commandString);			
			if(commandString != "")
			{
				subs = commandString.split(" ");
				command = subs[0];	
				parsedValue = Math.abs(parseInt(subs[1]))
			}			
			
			// Commands for use only when map is loaded and running
			if(mapRunning)
			{
				// One argument commands
				if(!isNaN(parsedValue))
				{
					switch(command)
					{
						case "show_unit_boundboxes":
							for each(var u:Unit in _units)
							{
								u.showBoundBox = Boolean(parsedValue);
							}
							break;
						case "show_terrain":
							// Show/hide regular meshes
							/*for each(var m:Mesh in mapMeshes)
							{
								m.visible = Boolean(parsedValue);
							}*/
							break;
						case "show_terrain_wireframe":
							// Show/hide wireframes
							for each(var w:WireFrame in mapWireframes)
							{
								w.visible = Boolean(parsedValue);
							}
							break;
						case "show_colmesh":
							Globals.library.getObjectByName("wireframe_colmesh").visible = Boolean(parsedValue);
							break;
						case "show_light_sources":
							renderer3D.debugLights = Boolean(parsedValue);
							break;
						case "light_enable_omni":
							for each(o in Globals.library.lights)
							{
								if(o is OmniLight)
								{
									o.visible = Boolean(parsedValue);
								}
							}
							break;
						case "light_enable_directional":
							for each(o in Globals.library.lights)
							{
								if(o is DirectionalLight)
								{
									o.visible = Boolean(parsedValue);
								}
							}
							break;
						case "light_enable_spot":
							for each(o in Globals.library.lights)
							{
								if(o is SpotLight)
								{
									o.visible = Boolean(parsedValue);
								}
							}
							break;
						case "light_enable_ambient":
							for each(o in Globals.library.lights)
							{
								if(o is AmbientLight)
								{
									o.visible = Boolean(parsedValue);
								}
							}
							break;
						case "use_camera_mode":
							switch(parsedValue)
							{
								case 1:
									this.cameraController = _fpsController;
									break;
								case 2:
									this.cameraController = _freeRoamController;
									break;
							}
							break;
					}
				} else {
					// No-argument commands
					switch(command)
					{
						case "ping":
							trace("ping");
							break;
						default:
							return "Invalid command.";
					}
				}				
			} else {
				return "Map is not initialized.";
			}
			
			return "";
		}
		
		/*---------------------------
		Debug methods
		---------------------------*/
		
		private function lightsSwitchCallback(e:Event):void
		{
			renderer.debugLights = !renderer.debugLights;
		}
		
		private function generateWireframes():void
		{
			/*---------------------------
			Map geometry wireframe
			---------------------------*/
			
			for each(var m:Mesh in Globals.library.mapMeshes)
			{
				var color:uint = MAP_DEFAULT_COLOR;
				
				if(m.name.substr(0, 4) == "mesh")
					color = MAP_MESH_COLOR;
				else if(m.name.substr(0, 7) == "terrain")
				{
					color = MAP_TERRAIN_COLOR;
				}
				
				var w:WireFrame = WireFrame.createEdges(m, color);
				w.name = "wireframe_" + m.name;
				w.visible = false;
				renderer.addObject3D(w, true);
				mapWireframes.push(w);
			}
			
			/*---------------------------
			Collision mesh wireframe
			---------------------------*/
			
			// Generate navmesh wireframe
			var collisionMeshWireframe:WireFrame = WireFrame.createEdges(_collisionMesh, COLLISION_MESH_WIREFRAME_COLOR);
			renderer.addObject3D(collisionMeshWireframe, true);
			collisionMeshWireframe.visible = false;
			collisionMeshWireframe.name = "wireframe_colmesh";
			specialWireframes.push(collisionMeshWireframe);
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get collisionMesh():Mesh
		{
			return _collisionMesh;
		}
		
		public function get terrainMesh():Mesh
		{
			return _terrainMesh;
		}
		
		public function get guiController():GuiController
		{
			return _guiController;
		}
		
		public function get renderer():Renderer3D
		{
			return renderer3D;
		}
		
		public function get units():Vector.<Unit>
		{
			return _units;
		}
		
		public function get cameraController():ICameraController
		{
			return _cameraController;
		}
		public function set cameraController(controller:ICameraController):void
		{
			if(controller != _cameraController)
			{
				// Handle old controller (if present)
				if(_cameraController != null)
				{
					removeLoopCallbackPre(_cameraController.think);
					_cameraController.enabled = false;
				}				
				
				// Setup new controller
				_cameraController = controller;
				Globals.cameraController = controller;
				renderer3D.camera = controller.camera;
				addLoopCallbackPre(controller.think);
				_guiController.bringToTop();
			}
		}
	}
}