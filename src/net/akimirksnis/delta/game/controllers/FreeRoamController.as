package net.akimirksnis.delta.game.controllers
{
	import alternativa.engine3d.controllers.SimpleObjectController;
	import alternativa.engine3d.core.Camera3D;
	
	import flash.display.InteractiveObject;
	
	import net.akimirksnis.delta.game.controllers.interfaces.ICameraController;
	import net.akimirksnis.delta.game.utils.Globals;

	public class FreeRoamController extends SimpleObjectController implements ICameraController
	{
		protected var _enabled:Boolean = false;
		
		public function FreeRoamController(
			eventSource:InteractiveObject,
			camera:Camera3D,
			speed:Number = 2000,
			speedMultiplier:Number = 3,
			mouseSensitivity:Number = 1
		)
		{			
			super(eventSource, null, speed, speedMultiplier, mouseSensitivity);
			super.object = camera;
			super.accelerate(true);
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		public function think():void
		{
			super.update();
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get camera():Camera3D
		{
			return super.object as Camera3D;
		}
		public function set camera(camera:Camera3D):void
		{
			super.object = camera;			
		}		
		
		/**
		 * Indicates whether this component is enabled.
		 */
		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled(value:Boolean):void
		{
			if(_enabled && !value)
			{
				// ArgumentError: The supplied Object3D must be a child of the caller.
				//Globals.renderer.mainContainer.removeChild(this.camera);
				this.disable();
				_enabled = false;
			} else if(!_enabled && value)
			{
				Globals.renderer.mainContainer.addChild(this.camera);
				this.enable();
				_enabled = true;
			}
		}		
	}
}