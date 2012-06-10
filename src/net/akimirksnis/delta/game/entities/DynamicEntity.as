package net.akimirksnis.delta.game.entities
{
	import alternativa.engine3d.animation.AnimationController;
	import alternativa.engine3d.animation.AnimationSwitcher;
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.GeoSphere;
	
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.utils.Globals;

	public class DynamicEntity extends Entity
	{
		//Animation properties		
		protected var aniController:AnimationController;
		protected var aniSwitcher:AnimationSwitcher;
		protected var currentAnimation:String;
		
		// Collisions
		protected var collider:EllipsoidCollider
		
		/**
		 * Class constructor.
		 */
		public function DynamicEntity()
		{
			super();
			
			// Think each frame
			Core.instance.addLoopCallbackPost(think);
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
			
			// Calculate collider by model bounds
			collider = new EllipsoidCollider(
				(model.boundBox.maxX - model.boundBox.minX) / 2,
				(model.boundBox.maxY - model.boundBox.minY) / 2,
				(model.boundBox.maxZ - model.boundBox.minZ) / 2
			);
			
			if(Globals.DEBUG_MODE)
			{
				var rutul:GeoSphere = new GeoSphere(1,10,false,new FillMaterial(0xAAFF00, 0.4));
				Globals.renderer.uploadResources(rutul.getResources());
				this._mesh.addChild(rutul);
				rutul.scaleX = collider.radiusX;
				rutul.scaleY = collider.radiusY;
				rutul.scaleZ = collider.radiusZ;
				rutul.z = this._mesh.boundBox.maxZ / 2;
			}
		}
		
		/**
		 * Sets up animation support for this entity.
		 */
		protected function setupAnimations():void
		{
			aniController = new AnimationController();
			aniSwitcher = new AnimationSwitcher();
		}
	}
}