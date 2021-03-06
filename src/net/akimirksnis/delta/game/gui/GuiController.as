package net.akimirksnis.delta.game.gui
{	
	import com.bit101.components.Component;
	import com.bit101.components.Overlay;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	
	import net.akimirksnis.delta.game.controllers.interfaces.IController;
	import net.akimirksnis.delta.game.gui.controllers.ComponentController;
	import net.akimirksnis.delta.game.gui.controllers.DebugOverlayController;
	import net.akimirksnis.delta.game.gui.controllers.LevelSelectionOverlayController;
	import net.akimirksnis.delta.game.gui.controllers.OverlayController;
	import net.akimirksnis.delta.game.gui.controllers.PreloaderOverlayController;
	import net.akimirksnis.delta.game.utils.Globals;

	[Event(name="DisplayStateChanged", type="net.akimirksnis.delta.game.gui.GuiController")]
	public class GuiController extends EventDispatcher implements IController
	{		
		public static const DISPLAY_STATE_CHANGED:String = "DisplayStateChanged";
		
		private static var _allowInstantiation:Boolean = false;
		private static var _instance:GuiController = new GuiController(SingletonLock);
		
		private var components:Vector.<Component> = new Vector.<Component>();	
		private var _enabled:Boolean = true;
		private var _fellowControllers:Vector.<IController> = new Vector.<IController>();
		private var currentlyPressedKeys:Object = new Object();
		private var GUIRoot:DisplayObjectContainer = new Sprite();
		private var overlayControllers:Vector.<ComponentController> = new Vector.<ComponentController>();
		private var previouslyEnabledController:IController;
		
		// Controllers
		private var debugOverlayController:DebugOverlayController;		
				
		/**
		 * Initializes GUI components.
		 */
		public function GuiController(lock:Class):void
		{
			Globals.stage.addChild(GUIRoot);
			Globals.GUIRoot = GUIRoot;
			
			// Add overlay controllers
			
			// Debug overlay
			if(Globals.DEBUG_MODE)
			{
				debugOverlayController = new DebugOverlayController("DebugOverlayController");
				addOverlayController(debugOverlayController);
			}			
			
			// Preloader overlay
			addOverlayController(new PreloaderOverlayController("PreloaderOverlayController"));
			
			// Level selection overlay
			addOverlayController(new LevelSelectionOverlayController("LevelSelectionOverlayController"));
			
			attachListeners();
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
	
		/**
		 * Adds overlay controller.
		 * 
		 * @param controller Controller to add.
		 */
		public function addOverlayController(controller:ComponentController):ComponentController
		{
			overlayControllers.push(controller);
			controller.enabled = false;
			GUIRoot.addChild(controller.component);
			return controller;
		}
		
		/**
		 * Removes overlay controller.
		 * 
		 * @param controller Controller to remove.
		 */
		public function removeOverlayController(controller:ComponentController):void
		{
			var controllerIndex:int = overlayControllers.indexOf(controller);
			
			if(controllerIndex != -1)
			{
				overlayControllers.splice(controllerIndex, 1); 
			}
		}
		
		/**
		 * Returns overlay controller by name.
		 * 
		 * @param name Name of the controller.
		 * @return Controller with given name or null if controler do not exist.
		 */
		public function getOverlayControllerByName(name:String):OverlayController
		{
			for each(var c:OverlayController in overlayControllers)
			{
				if(c.name == name)
					return c;
			}
			
			return null;
		}
		
		/**
		 * Brings specified overlay to focus. All other active overlays are
		 * disabled (except ones with multiFocusEnabled set to true).
		 * 
		 * @param name Name of the overlay.
		 */
		public function focusOverlay(name:String):void
		{
			var controller:OverlayController;
			
			for each(var c:OverlayController in overlayControllers)
			{
				if(c.name == name)
					controller = c;
			}
			
			if(controller == null)
			{
				return;
			}
			
			controller.enabled = true;
			
			if(!Overlay(controller.component).multiFocusEnabled)
			{
				for each(c in overlayControllers)
				{
					if(c != controller)
						c.enabled = false;
				}
			}
		}
		
		/**
		 * Disables specified overlay.
		 * 
		 * @param name Name of the overlay.
		 */
		public function unfocusOverlay(name:String):void
		{
			for each(var c:OverlayController in overlayControllers)
			{
				c.enabled = c.name == name ? false : c.enabled;
			}
		}
		
		/**
		 * Hides all overlays.
		 */
		public function unfocusAll():void
		{
			for each(var c:ComponentController in overlayControllers)
			{
				c.enabled = false;
			}
		}
		
		/**
		 * Moves Gui container above all other display objects (camera.view and camera.diagram)
		 */
		public function bringToTop():void
		{
			Globals.stage.setChildIndex(GUIRoot, Globals.stage.numChildren - 1);
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		/**
		 * Key up keyboard event handler.
		 * @param e Event object.
		 */
		private function onKeyUp(e:KeyboardEvent):void
		{
			// Key: F1
			// Show/hide debug overlay
			if(Globals.DEBUG_MODE)
			{
				if(e.keyCode == 112)
				{
					if(debugOverlayController.enabled)
					{
						var differs:Boolean = false;
						
						for each(var c:IController in _fellowControllers)
						{
							if(c.enabled)
							{
								differs = true;
								break;
							}
						}
						
						if(!differs && previouslyEnabledController != null)
						{
							previouslyEnabledController.enabled = true;
						}
						
						debugOverlayController.unfocus();
					} else {
						for each(c in _fellowControllers)
						{
							if(c.enabled)
							{
								previouslyEnabledController = c;
								c.enabled = false;
							}
						}
						debugOverlayController.focus();
					}			
				}
			}
			
			// Key: F12
			// Enter fullscreen mode
			if(e.keyCode == 123)
			{
				if(Globals.stage.displayState == StageDisplayState.NORMAL)
				{
					Globals.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				} else {
					Globals.stage.displayState = StageDisplayState.NORMAL;
					// Flash disables mouse lock automatically
				}
				
				dispatchEvent(new Event(DISPLAY_STATE_CHANGED));
			}
			
			// Key: Esc
			// Escape full screen, disable mouseLock
			if(e.keyCode == 27)
			{
				dispatchEvent(new Event(DISPLAY_STATE_CHANGED));
			}
		}
		
		/**
		 * Handles stage resize.
		 * @param e Event object.
		 */
		private function onStageResize(e:Event):void
		{
			for each(var controller:ComponentController in overlayControllers)
			{
				controller.invalidateView();
			}
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/**
		 * @private
		 */
		private function attachListeners():void			
		{	
			Globals.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
			Globals.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
		}
		
		/**
		 * @private
		 */
		private function detachListeners():void			
		{		
			Globals.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp, false);
			Globals.stage.removeEventListener(Event.RESIZE, onStageResize, false);
		}
		
		/*---------------------------
		Setters/getters
		---------------------------*/
		
		/**
		 * Returns singleton of this class.
		 */
		public static function get instance():GuiController
		{			
			return _instance;
		}
		
		public function set enabled(value:Boolean):void
		{
			if(_enabled && !value)
			{
				detachListeners();
				_enabled = false;
			}
			if(!_enabled && value)
			{
				attachListeners();
				_enabled = true;
			}
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function get fellowControllers():Vector.<IController>
		{
			return _fellowControllers;
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		public function dispose():void
		{
			detachListeners();
		}
	}
}

class SingletonLock {}