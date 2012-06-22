package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.materials.TextureMaterial;
	import alternativa.engine3d.objects.SkyBox;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.resources.BitmapTextureResource;
	
	import com.bit101.components.Style;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.cameras.DebugFRCamera;
	import net.akimirksnis.delta.game.cameras.FPSCamera;
	import net.akimirksnis.delta.game.controllers.*;
	import net.akimirksnis.delta.game.controllers.interfaces.*;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.units.Walker2;
	import net.akimirksnis.delta.game.gui.GuiController;
	import net.akimirksnis.delta.game.gui.controllers.DebugOverlayController;
	import net.akimirksnis.delta.game.gui.controllers.LevelSelectionOverlayController;
	import net.akimirksnis.delta.game.gui.controllers.PreloaderOverlayController;
	import net.akimirksnis.delta.game.loaders.CoreLoader;
	import net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent;
	import net.akimirksnis.delta.game.net.OnlineGameManager;
	import net.akimirksnis.delta.game.net.P2PController;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Logger;
	
	use namespace delta_internal;

	[Event(name="commandExecuted", type="flash.events.Event")]
	public class Core extends EventDispatcher
	{
		private static var _instance:Core = new Core(SingletonLock);
		
		// Renderer
		private var renderer:Renderer3D;
		
		// Collections	
		private var loopCallbacksPre:Vector.<Function> = new Vector.<Function>();
		private var loopCallbacksPost:Vector.<Function> = new Vector.<Function>();
		
		// Controllers		
		private var _cameraController:ICameraController;
		private var guiController:GuiController;		
		private var fpsController:ICameraController;
		private var freeRoamController:ICameraController;
		private var netController:P2PController;
		private var onlineGameManager:OnlineGameManager;

		delta_internal var loader:CoreLoader
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
		
			// Component style
			Style.setStyle(Style.DARK);
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
			
			netController = P2PController.instance;
			onlineGameManager = OnlineGameManager.instance;
			onlineGameManager.netController = netController;
			
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
			// 1. Assets config
			// 2. Animations config
			var XMLPaths:Array = [
				Globals.LOCAL_ROOT + Globals.ASSETS_XML,
				Globals.LOCAL_ROOT + Globals.ANIMATIONS_XML,
			];

			// Create new CoreLoader instance and load base assets
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
			renderer = Renderer3D.instance;
			
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
		Map handlers
		---------------------------*/
		
		/**
		 * Creates a listen server for specified map.
		 * 
		 * @param Map filename with extension.
		 */
		delta_internal function loadMap(filename:String):void
		{
			unloadMap();			
			loader.loadMap(filename);
		}
		
		/**
		 * Unloads current map.
		 */
		delta_internal function unloadMap():void
		{		
			if(GameMap.currentMap != null)
			{
				// Stop main loop
				Globals.stage.removeEventListener(Event.ENTER_FRAME, think);			
				
				// Reset camera controller
				cameraController = null;
				(fpsController as FPSController).dispose();
				(freeRoamController as FreeRoamController).dispose();
	
				// Remove map from display hierarchy and dispose all its resources
				GameMap.currentMap.dispose();
				
				// Focus level selection overlay
				(guiController.getOverlayControllerByName("LevelSelectionOverlayController") as LevelSelectionOverlayController).focus();
				
				// Reset hierarchy in debug overlay (show hierachy for main scene container)
				if(Globals.DEBUG_MODE)
				{
					DebugOverlayController(guiController.getOverlayControllerByName("DebugOverlayController")).hierarchyWindowSource = renderer.mainContainer;
				}
			}
		}
		
		/*---------------------------
		Online game group creation
		---------------------------*/
		
		/**
		 * Creates an online game for specified map.
		 * 
		 * @param Map filename with extension.
		 */
		delta_internal function createOnlineGame(filename:String):void
		{
			onlineGameManager.joinOnlineGame("4ag4j4a987h41agasg7fh77yyklj8l74", filename);		
		}
		
		/**
		 * Joins an online game.
		 */
		delta_internal function joinOnlineGame(groupName:String):void
		{
			onlineGameManager.joinOnlineGame(groupName);
		}
		
		/**
		 * Disconnects current online game.
		 */
		delta_internal function disconnectOnlineGame():void
		{			
			onlineGameManager.disconnectOnlineGame();
		}
		
		/*---------------------------
		TEST
		---------------------------*/
			
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
		private var originX:WireFrame;
		private var originY:WireFrame;
		private var originZ:WireFrame;
		
		/**
		 * Fired after map is loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapLoaded(e:Event):void
		{		
			Logger.log("[Core] > Map loaded:", GameMap.currentMap.name);		
			
			var map:GameMap = GameMap.currentMap;
			guiController.unfocusAll();
			
			// Set hierarchy in debug overlay
			if(Globals.DEBUG_MODE)
			{
				DebugOverlayController(guiController.getOverlayControllerByName("DebugOverlayController")).hierarchyWindowSource = map;
			}			
			
			// Add map for rendering
			renderer.addObject3D(map);
			
			// Handle debug mode
			if(Globals.DEBUG_MODE)
			{				
				// Debug lights
				renderer.debugLights = true;
			}
			
			// SKYBOX
			
			// create once
			// todo: laodable skyboxes
			if(!sb)
			{
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
			}
			
			// CHARACTER
			
			var unit:Unit = new Walker2();
			map.addEntity(unit, "marker-spawn1");
			
			/*var oc:Occluder = new Occluder();
			var ocp:Plane = new Plane(10000,10000,1,1,true,false, new FillMaterial(0xFFF000, 0.25),new FillMaterial(0xFFF000, 0.25));
			ocp.rotationX = 3.14 / 2;
			ocp.z = 7500;
			renderer.addObject3D(ocp, true);
			oc.createForm(ocp.geometry);
			oc.z = 7500;
			oc.rotationX = 3.14 / 2;
			renderer.addObject3D(oc);*/
			
			// Origin marker
			// create once
			if(Globals.DEBUG_MODE && originX == null)
			{
				originX = WireFrame.createLinesList(Vector.<Vector3D>([new Vector3D(0, 0, 0), new Vector3D(300, 0, 0),  new Vector3D(300, 0, 0),  new Vector3D(280, 10, 0),  new Vector3D(300, 0, 0),  new Vector3D(280, -10, 0) ]), 0x0000ff, 2);
				originY = WireFrame.createLinesList(Vector.<Vector3D>([new Vector3D(0, 0, 0), new Vector3D(0, 300, 0), new Vector3D(0, 300, 0),new Vector3D(0, 280, 10),new Vector3D(0, 300, 0),new Vector3D(0, 280, -10)  ]), 0xff0000, 2);
				originZ = WireFrame.createLinesList(Vector.<Vector3D>([new Vector3D(0, 0, 0), new Vector3D(0, 0, 300), new Vector3D(0, 0, 300),new Vector3D(10, 0, 280),new Vector3D(0, 0, 300),new Vector3D(-10, 0, 280) ]), 0x00ff00, 2);
				
				renderer.addObject3D(originX, true);
				renderer.addObject3D(originY, true);
				renderer.addObject3D(originZ, true);
			}		
			
			// CONTROLLERS
			
			// Create standart unit.camera controller
			fpsController = new FPSController(Globals.stage, new FPSCamera(), unit);
			freeRoamController = new FreeRoamController(Globals.stage, new DebugFRCamera());
			guiController.fellowControllers.push(fpsController, freeRoamController);
			
			// Set current camera controller
			this.cameraController = fpsController;			

			// Move GUI controller to the top
			guiController.bringToTop();
			
			// Start main loop
			Globals.stage.addEventListener(Event.ENTER_FRAME, think);
		}
		
		/*---------------------------
		Render loop
		---------------------------*/
		//private var ff:uint = 0;
		/**
		 * Main render loop
		 * 
		 * @param e Event object.
		 */
		private function think(e:Event):void
		{			
			// Measure code execution time - start
			renderer.camera.startTimer();
			renderer.camera.startCPUTimer();
			
			//netController.sendString(ff + "");
			//ff++;
			
			// Run loop callbacks (1)
			for each(var callback:Function in loopCallbacksPre)
			{
				callback();
			}
			
			// Run loop callbacks (2)
			for each(callback in loopCallbacksPost)
			{
				callback();
			}
			
			// Measure code execution time - stop
			renderer.camera.stopTimer();
			
			// Render frame
			renderer.renderFrame();
		}
		
		/**
		 * Adds function to execute before rendering frame.
		 * 
		 * @param f Function to add.
		 */
		public function addLoopCallbackPre(f:Function):void
		{
			loopCallbacksPre.push(f);
		}
		
		/**
		 * Adds function to execute before rendering frame but after executing "Pre" sequence.
		 * 
		 * @param f Function to add.
		 */
		public function addLoopCallbackPost(f:Function):void
		{
			loopCallbacksPost.push(f);
		}
		
		/**
		 * Removes function from "Pre" rendering execution queue.
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
					break;
				}
			}
		}
		
		/**
		 * Removes function from "Post" rendering execution queue.
		 * 
		 * @param f Function to remove.
		 */
		public function removeLoopCallbackPost(functionToRemove:Function):void
		{
			for each(var f:Function in loopCallbacksPost)
			{
				if(f == functionToRemove)
				{
					loopCallbacksPost.splice(loopCallbacksPost.indexOf(f), 1);
					break;
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
		
		/**
		 * Forces to use FPS controller.
		 */
		public function useFPSController():void
		{
			this.cameraController = fpsController;
		}
		
		/**
		 * Forces to use free roam controller.
		 */
		public function useFreeRoamController():void
		{
			this.cameraController = freeRoamController;
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
		
		public function get lastResponse():String
		{
			return commandExecutor.lastResponse;
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
				
				if(controller != null)
				{
					renderer.camera = controller.camera;
					addLoopCallbackPre(controller.think);
					_cameraController.enabled = true;					
				} else {
					renderer.camera = null;
				}
				
				guiController.bringToTop();
			}
		}
	}
}

class SingletonLock {}