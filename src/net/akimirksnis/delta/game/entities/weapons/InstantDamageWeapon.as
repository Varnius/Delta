package net.akimirksnis.delta.game.entities.weapons
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.core.Renderer3D;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.utils.Globals;

	public class InstantDamageWeapon extends Weapon
	{
		// Time tracking		
		private var timeNow:int;
		private var lastTime:int;
		
		private var origin:Vector3D = new Vector3D();
		private var direction:Vector3D = new Vector3D();
		private var intersection:RayIntersectionData;
		private var localDirection:Vector3D = new Vector3D();
		
		use namespace alternativa3d;
		
		/**
		 * Class constructor.
		 * @ unit Unit Unit which posesses the weapon.
		 */
		public function InstantDamageWeapon(unit:Unit)
		{
			super(unit);
		}
		
		/*---------------------------
		Public methods
		---------------------------*/	
		
		//debug
		private var line:WireFrame;		
		private var quad:WireFrame;
		
		/**
		 * Uses primary fire of this weapon.
		 */
		public override function usePrimaryFire():void
		{
			super.usePrimaryFire();
			
			var intersectionPoint:Vector3D;
			var closestStaticIntersection:RayIntersectionData;
			var finalIntersection:RayIntersectionData;
			var time:uint = getTimer();
			//trace(time);
			
			// Calculate ray from camera (in global space)
			Renderer3D.instance.camera.calculateRay(
				origin,
				direction,
				Globals.stage.stageWidth / 2,
				Globals.stage.stageHeight / 2
			);
			
			/*---------------------------
			Handle static colliders
			---------------------------*/
			
			// Get list of visible static colliders
			var colliders:Vector.<Object3D> = GameMap.currentMap.staticCollisionOctree.getCollidersByFrustum(Renderer3D.instance.frustum);			
			
			// Intersect all visible static colliders
			for each(var c:Object3D in colliders)
			{
				// Convert direction from global to local space, since intersectRay() requires local coordinates :(
				localDirection.x = c.inverseTransform.a * direction.x + c.inverseTransform.b * direction.y + c.inverseTransform.c * direction.z;
				localDirection.y = c.inverseTransform.e * direction.x + c.inverseTransform.f * direction.y + c.inverseTransform.g * direction.z;
				localDirection.z = c.inverseTransform.i * direction.x + c.inverseTransform.j * direction.y + c.inverseTransform.k * direction.z;			
				
				intersection = c.intersectRay(c.globalToLocal(origin), localDirection);
				
				if(intersection != null)
				{
					if(closestStaticIntersection != null)
					{
						closestStaticIntersection = intersection.time < closestStaticIntersection.time ? intersection : closestStaticIntersection;
					} else {
						closestStaticIntersection = intersection;
					}
				}
			}
			
			/*---------------------------
			Handle dynamic colliders
			---------------------------*/
			
			var closestDynamicIntersection:RayIntersectionData;
			
			// Get list of visible dynamic colliders
			colliders = GameMap.currentMap.dynamicCollisionOctree.getCollidersByFrustum(Renderer3D.instance.frustum);

			// Intersect all visible dynamic colliders
			for each(c in colliders)
			{
				// Convert direction from global to local space, since intersectRay() requires local coordinates :(
				localDirection.x = c.inverseTransform.a * direction.x + c.inverseTransform.b * direction.y + c.inverseTransform.c * direction.z;
				localDirection.y = c.inverseTransform.e * direction.x + c.inverseTransform.f * direction.y + c.inverseTransform.g * direction.z;
				localDirection.z = c.inverseTransform.i * direction.x + c.inverseTransform.j * direction.y + c.inverseTransform.k * direction.z;			
				
				intersection = c.intersectRay(c.globalToLocal(origin), localDirection);
				
				if(intersection != null)
				{
					if(closestDynamicIntersection != null)
					{
						closestDynamicIntersection = intersection.time < closestDynamicIntersection.time ? intersection : closestDynamicIntersection;
					} else {
						closestDynamicIntersection = intersection;
					}
				}
			}
			
			// Find closest intersection (if any)
			if(closestStaticIntersection != null && closestDynamicIntersection != null)
			{
				finalIntersection = closestStaticIntersection.time < closestDynamicIntersection.time ? closestStaticIntersection : closestDynamicIntersection;
				
			} else if(closestStaticIntersection != null)
			{
				finalIntersection = closestStaticIntersection;
				
			} else if(closestDynamicIntersection != null)
			{
				finalIntersection = closestDynamicIntersection;
			} else {
				//
			}
			
			// If intersection exists
			if(finalIntersection != null)
			{			
				intersectionPoint = finalIntersection.object.localToGlobal(finalIntersection.point);
				
				// debug start
				if(Globals.DEBUG_MODE)
				{
					if(quad != null)
						renderer.removeObject3D(quad, true);
					quad = WireFrame.createEdges(new Box(25,25,25,1,1,1),0x00FF00,1,2);
					quad.x = intersectionPoint.x;
					quad.y = intersectionPoint.y;
					quad.z = intersectionPoint.z;
					renderer.addObject3D(quad, true);		
					
					if(line != null)
						renderer.removeObject3D(line, true);
					var linev:Vector.<Vector3D> = new Vector.<Vector3D>();
					linev.push(intersectionPoint, new Vector3D(origin.x, origin.y, origin.z - 25));
					line = WireFrame.createLinesList(linev, 0x00FF00);
					renderer.addObject3D(line, true);
				}
				//debug end
			}
			
			//trace(finalIntersection);
		}
		
		/**
		 * Use secondary weapon fire.
		 */
		public override function useSecondaryFire():void
		{
			super.useSecondaryFire();
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		/**
		 * Should be called when the object  is no longer needed.
		 */
		public override function dispose():void
		{
			super.dispose();
			
			if(Globals.DEBUG_MODE)
			{
				if(quad)
				{
					renderer.removeObject3D(quad, true);
				}
				
				if(line)
				{
					renderer.removeObject3D(line, true);
				}
			}
		}
	}
}