package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.SkyBox;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.resources.BitmapTextureResource;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.cameras.DebugFRCamera;
	import net.akimirksnis.delta.game.cameras.FPSCamera;
	import net.akimirksnis.delta.game.controllers.*;
	import net.akimirksnis.delta.game.controllers.interfaces.*;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.statics.Teapot;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.units.Walker2;
	import net.akimirksnis.delta.game.gui.controllers.LevelSelectionOverlayController;
	import net.akimirksnis.delta.game.gui.controllers.PreloaderOverlayController;
	import net.akimirksnis.delta.game.library.Library;
	import net.akimirksnis.delta.game.loaders.CoreLoader;
	import net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent;
	import net.akimirksnis.delta.game.namespaces.delta_internal;
	import net.akimirksnis.delta.game.utils.Globals;
	
	use namespace delta_internal;

	[Event(name="commandExecuted", type="flash.events.Event")]
	public class Core extends EventDispatcher
	{
		// Singleton
		private static var _instance:Core = new Core(SingletonLock);	
		
		// Unit in control		
		private var _unit:Unit;
		
		// Renderer
		private var renderer3D:Renderer3D;
		
		// Collections		
		private var entities:Vector.<Entity> = new Vector.<Entity>();
		private var _units:Vector.<Unit> = new Vector.<Unit>();
		private var loopCallbacks:Vector.<Function> = new Vector.<Function>();
		private var _mapWireframes:Vector.<WireFrame> = new Vector.<WireFrame>();
		private var specialWireframes:Vector.<WireFrame> = new Vector.<WireFrame>();
		
		// Controllers		
		private var guiController:GuiController;
		private var _cameraController:ICameraController;
		private var _fpsController:ICameraController;
		private var _freeRoamController:ICameraController;
		
		// Pathfinding		
		private var _mapRunning:Boolean;

		// Loader
		delta_internal var loader:CoreLoader
		
		// Command executor
		delta_internal var commandExecutor:CommandExecuter;
		
		// Library
		private var library:Library = Library.instance;
		
		/**
		 * Class constructor.
		 */
		public function Core(lock:Class)
		{			
			if(lock != SingletonLock)
			{
				throw new Error("The class 'Core' is singleton. Use 'Core.instance'.");
			}
			
			// Set global reference
			Globals.gameCore = this;		
		}
		
		/**
		 * Handles everything that should be done at app start.
		 */
		public function init():void
		{
			// Create Gui controller (must be created before all other controllers!)
			// This is because it handles all graphical 2D interface, including menus, preloaders and more..
			guiController = GuiController.instance;
			guiController.enabled = false;
			
			// Create command executer
			commandExecutor = CommandExecuter.instance;			
			
			// Request context3D and initialize 3D renderer
			Globals.stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
			Globals.stage3D.requestContext3D();
		}
		
		/*---------------------------
		Event callbacks
		---------------------------*/

		/**
		 * Fired after context3D is acquired.
		 * 
		 * @param e Event object.
		 */
		private function onContext3DCreated(e:Event):void
		{
			Globals.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContext3DCreated);
			
			// Paths to config XML files
			// 1. Assets file (currently config only)
			var XMLPaths:Array = [
				Globals.LOCAL_ROOT + Globals.ASSETS_XML
			];

			// Load base assets
			loader = new CoreLoader(XMLPaths, PreloaderOverlayController(guiController.getOverlayControllerByName("PreloaderOverlayController")));			
			loader.addEventListener(CoreLoaderEvent.ASSETS_LOADED, onAssetsLoaded, false, 0, true);			
			loader.loadAssets();
		}
		
		/**
		 * Fired after all assets are loaded.
		 * 
		 * @param e Event object.
		 */
		private function onAssetsLoaded(e:Event):void
		{	
			loader.removeEventListener(CoreLoaderEvent.ASSETS_LOADED, onAssetsLoaded);
			
			// Create renderer
			renderer3D = Renderer3D.instance;
			Globals.renderer = renderer3D;
			
			// Bring GUI to top
			guiController.bringToTop();
			guiController.enabled = true;
			
			// Add event listener for map loaded event
			loader.addEventListener(CoreLoaderEvent.MAP_LOADED, onMapLoaded, false, 0, true);
			
			// Focus level selection overlay
			var levelSelectionController:LevelSelectionOverlayController = guiController.getOverlayControllerByName("LevelSelectionOverlayController") as LevelSelectionOverlayController;			
			levelSelectionController.mapData = library.mapData;		
			levelSelectionController.focus();
		}
		
		/*---------------------------
		TEST
		---------------------------*/
		
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
		 * Fired after map is loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapLoaded(e:Event):void
		{	
			trace('core: map loaded');
			guiController.unfocusAll();	
			
			// Add map for rendering
			renderer.addObject3D(library.map);
			
			// Handle debug mode
			if(Globals.debugMode)
			{				
				// Debug lights
				renderer.debugLights = true;
			}
			
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
			
			
			// CHARACTER			
			renderer.mainContainer.calculateBoundBox();
			var obj:Object3D = library.getMapObjectByName("pointer-spawn1");
			
			_unit = new Walker2();
			library.map.addChild(_unit.model);
			_unit.model.x = obj.x;
			_unit.model.y = obj.y;
			_unit.model.z = obj.z;
			_units.push(_unit);			
			ctents.push(_unit);
			
			/*var statice:Teapot = new Teapot();
			library.map.addChild(statice.model);
			statice.model.x = 1000;
			statice.model.z = 0;
			statice.showBoundBox = true;
			ctents.push(statice);*/
			
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
			guiController.fellowControllers.push(_fpsController, _freeRoamController);
			
			// Set current camera controller
			this.cameraController = _fpsController;			
			
			// Map initialization is complete
			_mapRunning = true;
			// Move GUI controller to the top
			guiController.bringToTop();
			//Start main loop			
			startThinking();
		}
		
		/*---------------------------
		Render loop
		---------------------------*/
		
		/**
		 * Starts render loop.
		 */
		private function startThinking():void
		{
			// Start main loop
			Globals.stage.addEventListener(Event.ENTER_FRAME, think);
		}
		
		/**
		 * Stops render loop.
		 */
		private function stopThinking():void
		{
			// Start main loop
			Globals.stage.removeEventListener(Event.ENTER_FRAME, think);
		}
		
		/**
		 * Main render loop
		 * 
		 * @param e Event object.
		 */
		private function think(e:Event):void
		{			
			// Measure code execution time - start
			renderer.camera.startTimer();
			
			// Run loop callbacks (pre-render)
			for each(var callback:Function in loopCallbacks)
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
		public function addLoopCallback(f:Function):void
		{
			loopCallbacks.push(f);
		}
		
		/**
		 * Removes function from pre-frame rendering execution queue
		 * 
		 * @param f Function to remove.
		 */
		public function removeLoopCallbackPre(functionToRemove:Function):void
		{
			for each(var f:Function in loopCallbacks)
			{
				if(f == functionToRemove)
				{
					loopCallbacks.splice(loopCallbacks.indexOf(f), 1);
				}
			}
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		public function executeCommand(command:String):void
		{
			commandExecutor.executeCommand(command);
		}
		
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
		
		/**
		 * Forces to use FPS controller.
		 */
		public function useFPSController():void
		{
			this.cameraController = _fpsController;
		}
		
		/**
		 * Forces to use free roam controller.
		 */
		public function useFreeRoamController():void
		{
			this.cameraController = _freeRoamController;
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Returns class instance.
		 */
		public static function get instance():Core
		{			
			return _instance;
		}
		
		public function get lastCommand():String
		{
			return commandExecutor.lastCommand;
		}
		
		public function get lastResponse():String
		{
			return commandExecutor.lastResponse;
		}
		
		public function get mapRunning():Boolean
		{
			return _mapRunning;
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
				
				// Setup and enable new controller
				_cameraController = controller;
				Globals.cameraController = controller;
				renderer3D.camera = controller.camera;
				addLoopCallback(controller.think);
				_cameraController.enabled = true;
				guiController.bringToTop();
			}
		}
	}
}

class SingletonLock {}