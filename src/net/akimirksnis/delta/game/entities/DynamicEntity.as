package net.akimirksnis.delta.game.entities
{
	import alternativa.engine3d.animation.AnimationController;
	import alternativa.engine3d.animation.AnimationSwitcher;
	import alternativa.engine3d.objects.Mesh;
	
	import net.akimirksnis.delta.game.core.Core;

	public class DynamicEntity extends Entity
	{
		//Animation properties		
		protected var aniController:AnimationController;
		protected var aniSwitcher:AnimationSwitcher;
		protected var currentAnimation:String;
		
		/**
		 * Class constructor.
		 */
		public function DynamicEntity()
		{
			super();
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Updates entity state.
		 */
		public function think():void
		{
			// ..
		}
		
		/*---------------------------
		Setup helpers
		---------------------------*/
		
		/**
		 * @inherit
		 */
		protected override function setModel(model:Mesh):void
		{
			super.setModel(model);
		}
		
		/**
		 * Sets up animation support for this entity.
		 */
		protected function setupAnimations():void
		{
			aniController = new AnimationController();
			aniSwitcher = new AnimationSwitcher();
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		/**
		 * @inherit
		 */
		public override function dispose():void			
		{
			super.dispose();
			Core.instance.removeLoopCallbackPost(think);
		}
	}
}