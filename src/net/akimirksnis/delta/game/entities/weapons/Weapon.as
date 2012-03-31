package net.akimirksnis.delta.game.entities.weapons
{
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.GeoSphere;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.entities.AnimationType;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.units.Unit;
	
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;

	public class Weapon extends Entity
	{
		// Weapon characteristics
		
		// Weapon output point in local space
		protected var _fireOriginPoint:Vector3D;
		protected var _damage:int;
		protected var _range:int;
		
		// Animation types
		
		protected var aniIdle:AnimationClip;
		protected var aniAttack:AnimationClip;
		
		// Other instance vars
		
		protected var _unit:Unit;
		
		public function Weapon(unit:Unit)
		{
			super();
			_unit = unit;
		}
		
		protected override function setupAnimations():void
		{
			super.setupAnimations();
			
			// Get all animations for this type of entity model
			/*var animation:AnimationClip = Globals.core.getAnimationByName(super.type).clone();
			var animationFrames:String = Globals.core.getPropertiesByName(super.type)["animations"];
			var timeBounds:Vector.<Number> = new Vector.<Number>();
			
			animation.attach(model, true);
			
			if(animationFrames != null || animationFrames != "")
			{
				// Iterate through split parts of string
				for each (var sub:String in animationFrames.split("/"))
				{
					var subsub:Array = sub.split("-");
					
					// Split, parseint and push to vector exact frame bound numbers
					timeBounds.push(parseFloat(subsub[0]));
					timeBounds.push(parseFloat(subsub[1]));
				}
				
				//if(timeBounds.length < 2)
				//	throw new Error("[Unit] Less than two animation bounds found.");
				
				aniIdle = animation.slice(timeBounds[0] / 30, timeBounds[1] / 30);
				aniAttack = animation.slice(timeBounds[2] / 30, timeBounds[3] / 30);
				
				// Add animation slices to switcher
				aniSwitcher.addAnimation(aniIdle);
				//aniSwitcher.addAnimation(aniAttack);
				
				// Attach switcher as controller`s root
				aniController.root = aniSwitcher;	
				
				// Init idle animation
				aniSwitcher.activate(aniIdle, 0.1);
				
				// Register loop callback
				Globals.gameCore.addLoopCallbackPre(aniController.update);
			} else {
				throw new Error("[Unit] Animation properties of the weapon not found.");
			}*/
		}
		
		public function set animation(animation:String):void
		{
			switch(animation)
			{
				case AnimationType.UNIT_IDLE:
					currentAnimation = animation;
					aniSwitcher.activate(aniIdle);
					break;
				case AnimationType.UNIT_ATTACK:
					currentAnimation = animation;
					aniSwitcher.activate(aniAttack);
					break;
				default:
					trace("[Unit] Animation could not be set. Unknown animation: " + animation);
			}
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		public function usePrimaryFire():void
		{
			// Implemented in child classes
		}
		
		public function useSecondaryFire():void
		{
			// Implemented in child classes
		}
				
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get unit():Unit
		{
			return _unit;
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		public override function dispose():void
		{
			Globals.gameCore.removeLoopCallbackPre(aniController.update);
			super.dispose();
		}
	}
}