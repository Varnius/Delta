package net.akimirksnis.delta.game.controllers
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.objects.WireFrame;
	
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.display.StageDisplayState;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.controllers.interfaces.ICameraController;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	public class FPSController implements ICameraController
	{	
		// Constants		
		public static const MAX_PITCH:Number = Utils.degToRad(0);
		public static const MIN_PITCH:Number = Utils.degToRad(-180);		
		public static const MIN_FOV:Number = Utils.degToRad(70);
		public static const MAX_FOV:Number = Utils.degToRad(110);	
		public static const PI2:Number = Math.PI * 2;		
		
		// Regular attributes
		protected var _followUnit:Unit;
		protected var _camera:Camera3D;
		protected var _eventSource:InteractiveObject;
		protected var _enabled:Boolean = false;		
		protected var gameCursor:Sprite = new Sprite();
		
		// Input related variables
		public var mouseSensitivity:Number = 1.0;
		private var allowJumping:Boolean = true;
		private var allowPropulsing:Boolean = true;
		protected var currentlyPressedKeys:Object = new Object();
		protected var mouseLeftDown:Boolean;
		protected var mouseRightDown:Boolean;
		protected var mouseMovementX:Number;
		protected var mouseMovementY:Number;
		protected var velocityFromInput:Vector3D = new Vector3D();		
		
		// Debug
		protected var targetLine:WireFrame;
		protected var traceLine:WireFrame;
		
		/*---------------------------
		GUI elements
		---------------------------*/
		
		public function FPSController(eventSource:InteractiveObject, camera:Camera3D, followUnit:Unit = null)
		{
			_eventSource = eventSource;
			_camera = camera;			
			this.unit = followUnit;
			
			onStageResize();
		}
		
		/**
		 * This is run each frame.
		 */
		public function think():void
		{
			if(_enabled)
			{		
				// Handle keyboard input
				handleKeyboardInput();
				
				// Handle mouse input
				handleMouseInput();
				
				// Handle unit movement
				_followUnit.think();
				
				// Handle camera and unit
				handleCamera();				
				
				// Invalidate shared properties after tick
				mouseMovementX = mouseMovementY = 0;
			}
		}
		
		/*---------------------------
		Handlers
		---------------------------*/
		
		/**
		 * Handle mouse input. Run each frame.
		 */
		private function handleMouseInput():void
		{
			if(mouseLeftDown)
			{
				_followUnit.usePrimaryFire();
			} else if(mouseRightDown)
			{
				_followUnit.useSecondaryFire();	
			}
		}
		
		/**
		 * Handles keyboard input.
		 */
		private function handleKeyboardInput():void
		{		
			// Use a single Vector3D object for unit movement representation
			// x represents movement left or right
			// y represents movement forward or backward
			// z, w - currently not in use (todo: use z for jumps?)
			
			// A		
			if(currentlyPressedKeys[65])
			{				
				velocityFromInput.x = -1;
			}
				// or D
			else if(currentlyPressedKeys[68])
			{				
				velocityFromInput.x = 1;
			} else {
				velocityFromInput.x = 0;
			}
			
			// W
			if(currentlyPressedKeys[87])
			{				
				velocityFromInput.y = 1;
			}			
				// or S	
			else if(currentlyPressedKeys[83])
			{				
				velocityFromInput.y = -1;
			} else {
				velocityFromInput.y = 0;
			}
			
			// should be called once per tick
			_followUnit.addVelocityFromInput(velocityFromInput);			
		}
		
		/**
		 * Handles unit.
		 */
		private function handleCamera():void
		{			
			/*---------------------------
			Handle camera rotation
			---------------------------*/
			
			var percMovementX:Number, percMovementY:Number;
			
			// Update pith/yaw according to mouse movement
			if(Globals.stage.mouseLock)
			{
				// Calculate screen size relative amount of movement
				percMovementX = mouseMovementX / Globals.stage.stageWidth;
				percMovementY = mouseMovementY / Globals.stage.stageHeight;
				
				// Handle yaw
				_followUnit.mesh.rotationZ -= Math.PI * percMovementX * mouseSensitivity;				
				_followUnit.mesh.rotationZ = _followUnit.mesh.rotationZ > PI2 ? _followUnit.mesh.rotationZ - PI2 : _followUnit.mesh.rotationZ;
				_followUnit.mesh.rotationZ = _followUnit.mesh.rotationZ < -PI2 ? _followUnit.mesh.rotationZ + PI2 : _followUnit.mesh.rotationZ;
				
				// Handle pitch
				if(_camera.rotationX <= MAX_PITCH &&_camera.rotationX >= MIN_PITCH)
				{
					_camera.rotationX -= Math.PI * percMovementY * mouseSensitivity;
					
					if(_camera.rotationX > MAX_PITCH)
					{
						_camera.rotationX = MAX_PITCH;
					} else if(_camera.rotationX < MIN_PITCH)
					{
						_camera.rotationX = MIN_PITCH;
					}
				}
			}
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
			Globals.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false, 0, true);
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
			Globals.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove, false);
			_eventSource.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false);
			_eventSource.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp, false);
		}
		
		/**
		 * Handle key down input that does not require per-frame check.
		 */
		private function handleNonPerFrameKeyDown():void
		{
			// Key: 'o'
			// Enter fullscreen mode
			// todo: move to gui controller
			if(currentlyPressedKeys[79])
			{
				if(Globals.stage.displayState == StageDisplayState.NORMAL)
				{
					Globals.stage.displayState = StageDisplayState.FULL_SCREEN_INTERACTIVE;
					enableMouseLock();
				} else {
					Globals.stage.displayState = StageDisplayState.NORMAL;
					// Flash disables mouse lock automatically
					//disableMouseLock();
				}
			}
			
			// Jump - space (allow only once per tap)
			if(currentlyPressedKeys[32] && allowJumping)
			{
				_followUnit.jump();
				allowJumping = false;
			}
			
			// Propulse - shift (allow only once per tap)
			if(currentlyPressedKeys[16] && allowPropulsing)
			{
				_followUnit.propulse();
				allowPropulsing = false;
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
			//gameCursor.visible = true;			
		}
		
		/**
		 * Disables custom game cursor.
		 */
		private function disableGameCursor():void
		{		
			//gameCursor.visible = false;
			//Mouse.show();
		}
		
		/**
		 * Enables mouse lock if possible.
		 */
		private function enableMouseLock():void
		{
			if(Globals.stage.displayState == StageDisplayState.FULL_SCREEN_INTERACTIVE || Globals.stage.displayState == StageDisplayState.FULL_SCREEN)
			{
				Globals.stage.mouseLock = true;				
			}
		}
		
		/**
		 * Disables mouse lock.
		 */
		private function disableMouseLock():void
		{
			if(Globals.stage.mouseLock)
			{
				Globals.stage.mouseLock = false;				
			}
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		protected function onStageResize(e:Event = null):void
		{
			//
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
		
		private function onMouseMove(e:MouseEvent):void
		{			
			mouseMovementX = e.movementX;
			mouseMovementY = e.movementY;
		}
		
		/**
		 * Keyboard KEY_DOWN event handler.
		 */
		private function onKeyDown(e:KeyboardEvent):void
		{
			currentlyPressedKeys[e.keyCode] = true;
			
			// Handle keyboard input that does not require per-frame update
			handleNonPerFrameKeyDown();
		}
		
		/**
		 * Keyboard KEY_UP event handler.
		 */
		private function onKeyUp(e:KeyboardEvent):void
		{
			currentlyPressedKeys[e.keyCode] = false;
			
			// Space
			// Allow jumping again after space is released
			if(e.keyCode == 32)
			{
				allowJumping = true;
			}
			
			// Shift
			// Allow propulsing again after space is released
			if(e.keyCode == 16)
			{
				allowPropulsing = true;
			}
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
				disableMouseLock();
				//_followUnit.model.visible = true;	
				_enabled = false;				
			} else if(!_enabled && value)
			{
				attachListeners();
				enableGameCursor();
				enableMouseLock();
				//_followUnit.m.visible = false;
				_enabled = true;				
			}			
		}
		
		public function get unit():Unit
		{
			return _followUnit;
		}
		public function set unit(value:Unit):void
		{
			if(value != null)
			{
				_followUnit = value;
				_followUnit.mesh.addChild(_camera);
				//_camera.z += _followUnit.m.boundBox.maxZ * 0.95;
				_camera.z += _followUnit.mesh.boundBox.maxZ * 1.25;
				//_followUnit.m.visible = false;
				
				// todo
				//_camera.z += _followUnit.model.boundBox.maxZ * 3;				
				//_camera.y += _followUnit.model.boundBox.maxZ * 3;
				
				if(!_enabled)
				{
					this.enabled = true;
				}
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