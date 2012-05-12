package net.akimirksnis.delta.game.controllers
{
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.core.View;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.resources.Geometry;
	
	import com.bit101.components.Component;
	import com.bit101.components.Label;
	import com.bit101.components.List;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Segment;
	import net.akimirksnis.delta.game.utils.Utils;
	import net.akimirksnis.delta.game.cameras.IsometricCamera;
	import net.akimirksnis.delta.game.controllers.interfaces.ICameraController;
	import net.akimirksnis.delta.game.controllers.interfaces.IController;
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.entities.AnimationType;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.events.EntityMouseEvent3D;
	
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Vector3D;
	import flash.ui.Mouse;
	
	public class IsometricController implements ICameraController
	{	
		// Constants
		public const CAMERA_PUSH_ROTATION_AMOUNT:Number = Utils.degToRad(0);
		public const CAMERA_PUSH_SLIDE_AMOUNT:Number = 0.05;
		public const CROSSHAIR_MARGIN:Number = 0.8;
		
		// Regular attributes
		protected var _unit:Unit;
		protected var _camera:Camera3D;
		protected var _eventSource:InteractiveObject;
		protected var _enabled:Boolean = true;		
		protected var areaLength:Number;
		protected var areaWidth:Number;
		protected var gameCursor:Sprite = new Sprite();
		protected var middlePoint:Point;
		
		// Input related variables
		protected var currentlyPressedKeys:Object = new Object();
		protected var mouseLeftDown:Boolean;
		protected var mouseRightDown:Boolean;
		
		// Debug
		protected var targetLine:WireFrame;
		protected var traceLine:WireFrame;
		
		/*---------------------------
		GUI elements
		---------------------------*/
		
		public function IsometricController(eventSource:InteractiveObject, camera:Camera3D, unit:Unit = null)
		{
			_eventSource = eventSource;
			_camera = camera;
			if(unit != null)
			{
				_unit = unit;		
				attachListeners();
				
				// Handle crosshair
				_eventSource.stage.addChild(gameCursor);
				gameCursor.mouseEnabled = false;
				enableGameCursor();
			} else {
				_enabled = false;
			}
			
			// Determine length and width of visible area
			var origin:Vector3D  = new Vector3D(), direction:Vector3D = new Vector3D();
			var topLeftBound:Vector3D, bottomRightBound:Vector3D;
			var intersectionData:RayIntersectionData;
			
			_camera.calculateRay(origin, direction, 0, 0);
			intersectionData = Globals.gameCore.levelPlane.intersectRay(origin, direction);
			if(intersectionData != null)
			{
				topLeftBound = intersectionData.point;
			}
			
			_camera.calculateRay(origin, direction, Globals.stage.stageWidth, Globals.stage.stageHeight);
			intersectionData = Globals.gameCore.levelPlane.intersectRay(origin, direction);
			if(intersectionData != null)
			{
				bottomRightBound = intersectionData.point;
			}
			
			areaLength = bottomRightBound.x - topLeftBound.x;
			areaWidth = topLeftBound.y - bottomRightBound.y;
			
			onStageResize();
		}
		
		/**
		 * This is run each frame.
		 */
		public function think():void
		{
			if(_enabled)
			{
								
					handleKeyboardInput();			
					handleCameraPosition();
					handleMouseInput();
				
			}
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		protected function onStageResize(e:Event = null):void
		{
			middlePoint = new Point(_eventSource.stage.stageWidth / 2, _eventSource.stage.stageHeight / 2);
		}
		
		private function onMouseLeftDown(e:MouseEvent):void
		{
			mouseLeftDown = true;
		}
		
		private function onMouseLeftUp(e:MouseEvent):void
		{
			mouseLeftDown = false;
		}
		
		private function onMouseRightDown(e:MouseEvent):void
		{
			mouseRightDown = true;
		}
		
		private function onMouseRightUp(e:MouseEvent):void
		{
			mouseRightDown = false;
		}
		
		private function onMouseLeave(e:Event):void
		{			
			invalidateInput();
		}
		
		/**
		 * Keyboard KEY_DOWN event handler.
		 */
		private function onKeyDown(e:KeyboardEvent):void
		{
			currentlyPressedKeys[e.keyCode] = true;
			// Handle keyboard input that does not require per-frame update
			handleStaticInput();
		}
		
		/**
		 * Keyboard KEY_UP event handler.
		 */
		private function onKeyUp(e:KeyboardEvent):void
		{
			currentlyPressedKeys[e.keyCode] = false;
		}
		
		/*---------------------------
		Handlers
		---------------------------*/
		
		/**
		 * Handle mouse input.
		 */
		private function handleMouseInput():void
		{
			var mx:Number = _eventSource.mouseX;
			var my:Number = _eventSource.mouseY;
			
			// Adjust camera agle according to mouse pointer position
			// drugs
			/*if(CAMERA_PUSH_ROTATION_AMOUNT != 0)
			{			
				_camera.rotationY = MemeCamera.ROTATION_Y + CAMERA_PUSH_ROTATION_AMOUNT * (1 - _eventSource.stage.mouseX / middlePoint.x);
				_camera.rotationX = MemeCamera.ROTATION_X + CAMERA_PUSH_ROTATION_AMOUNT * (1 - _eventSource.stage.mouseY / middlePoint.y);
			}*/
			
			// Slide camera a bit in direction where the mouse points
			if(CAMERA_PUSH_SLIDE_AMOUNT != 0)
			{
				_camera.x += (_eventSource.stage.mouseX / middlePoint.x - 1) * CAMERA_PUSH_SLIDE_AMOUNT * areaLength;				
				_camera.y -= (_eventSource.stage.mouseY / middlePoint.y - 1) * CAMERA_PUSH_SLIDE_AMOUNT * areaWidth;	
			}
			
			// Adjust character rotation according to mouse pointer position						
			var y:Number, x:Number;
			x = mx - middlePoint.x;
			y = my - middlePoint.y;			
			_unit.m.rotationZ = -Math.atan2(y, x) + Utils.degToRad(90);
			
			gameCursor.x = mx;
			gameCursor.y = my;
			
			// Handle cursor rotation
			gameCursor.rotation = -Utils.radToDeg(_unit.m.rotationZ) + 180;			
			
			// Inform unit about mouse key presses
			if(mouseLeftDown)
			{
				_unit.usePrimaryFire();
			}
			
			if(mouseRightDown)
			{
				_unit.useSecondaryFire();
			}
		}
		
		/**
		 * Handle keyboard input.
		 */
		private function handleKeyboardInput():void
		{		
			// Handle pressed keyboard keys
			// Left arrow		
			if(currentlyPressedKeys[37])
			{		
				_unit.directionX = -1;			
			}
			// Right arrow
			else if(currentlyPressedKeys[39])
			{				
				_unit.directionX = 1;
			} else {
				_unit.directionX = 0;
			}
			
			// Up arrow
			if(currentlyPressedKeys[38])
			{				
				_unit.directionY = 1;
			
			}
			// Down arrow	
			else if(currentlyPressedKeys[40])
			{				
				_unit.directionY = -1;
			} else {
				_unit.directionY = 0;
			}
			
			// Update unit position
			_unit.normalMove();			
		}

		/**
		 * Handle camera position.
		 */
		private function handleCameraPosition():void
		{		
			_camera.x = unit.m.x - areaLength * Math.sin(Utils.degToRad(180) - Math.abs(_camera.rotationY));
			_camera.y = unit.m.y - areaWidth * Math.sin(Utils.degToRad(180) - Math.abs(_camera.rotationX)); 
			_camera.z = IsometricCamera.POSITION_Z + _unit.m.z;
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		protected function attachListeners():void			
		{
			// Add event listeners
			Globals.stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave, false, 0, true);
			Globals.stage.addEventListener(Event.RESIZE, onStageResize, false, 0, true);
			Globals.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseLeftDown, false, 0, true);
			Globals.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseLeftUp, false, 0, true);
			Globals.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseRightDown, false, 0, true);
			Globals.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseRightUp, false, 0, true);
			_eventSource.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
			_eventSource.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);			
		}
		
		protected function detachListeners():void			
		{
			// Remove unneeded event listeners
			Globals.stage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave, false);
			Globals.stage.removeEventListener(Event.RESIZE, onStageResize, false);
			Globals.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseLeftDown, false);
			Globals.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseLeftUp, false);
			Globals.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onMouseRightDown, false);
			Globals.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onMouseRightUp, false);
			_eventSource.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false);
			_eventSource.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp, false);
		}
		
		/**
		 * Handle all input that does not require per-frame check.
		 */
		private function handleStaticInput():void
		{
			// Alt + Enter
			// Enter fullscreen mode
			if(currentlyPressedKeys[13] && currentlyPressedKeys[18])
			{
				if(Globals.stage.displayState == StageDisplayState.NORMAL)
				{
					Globals.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
				} else {
					Globals.stage.displayState = StageDisplayState.NORMAL;
				}
			}
		}
		
		private function invalidateInput():void
		{
			// Invalidate any pressed keys
			for(var key:String in currentlyPressedKeys)
			{
				currentlyPressedKeys[key] = false;
			}
			
			// Invalidate mouse input
			mouseRightDown = mouseLeftDown = false;
		}
		
		/**
		 * Enables custom game cursor.
		 */
		private function enableGameCursor():void
		{		
			//Mouse.hide();
			gameCursor.visible = true;			
		}
		
		/**
		 * Disables custom game cursor.
		 */
		private function disableGameCursor():void
		{		
			gameCursor.visible = false;
			Mouse.show();
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get camera():Camera3D
		{
			return _camera;
		}
		public function set camera(camera:Camera3D):void
		{
			_camera = camera;
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled(value:Boolean):void
		{
			if(_enabled && !value)
			{
				detachListeners();
				disableGameCursor();
				invalidateInput();
				_enabled = false;
			}
			if(!_enabled && value)
			{
				attachListeners();
				enableGameCursor();
				_enabled = true;
			}
		}
		
		public function get unit():Unit
		{
			return _unit;
		}
		public function set unit(value:Unit):void
		{
			_unit = value;
			if(!_enabled)
			{
				this.enabled = true;
			}
		}
		
		public function get eventSource():InteractiveObject
		{
			return _eventSource;
		}
		public function set eventSource(value:InteractiveObject):void
		{
			_eventSource = value;
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