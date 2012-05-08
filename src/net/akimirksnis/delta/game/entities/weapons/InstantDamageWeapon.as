package net.akimirksnis.delta.game.entities.weapons
{
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.GeoSphere;
	
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.utils.Globals;

	public class InstantDamageWeapon extends Weapon
	{
		// Time tracking
		
		protected var timeNow:int;
		protected var lastTime:int;
		
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
		private var rutul:GeoSphere;
		private var rutul2:GeoSphere;
		private var line:WireFrame;
		private var line0:WireFrame;
		
		/**
		 * Use primary weapon fire.
		 */
		public override function usePrimaryFire():void
		{
			super.usePrimaryFire();
			
			// Origin and direction vectors for calculating ray from the camera
			var origin:Vector3D = new Vector3D(), direction:Vector3D = new Vector3D();
			var collisionMeshIntersectionData:RayIntersectionData, unitIntersectionData:RayIntersectionData;
			var intersectionPoint:Vector3D;
			var hitUnits:Vector.<Entity> = new Vector.<Entity>();
			var minHitDistance:Number;
			var unitToHit:Entity;
			
			// Calculate ray from camera
			Globals.renderer.camera.calculateRay(
				origin,
				direction,
				Globals.stage.mouseX,
				Globals.stage.mouseY
			);
			
			// Find where ray from camera (along crosshair) intersects collision mesh
			collisionMeshIntersectionData = GameMap.currentMap.collisionMesh.intersectRay(origin, direction);
			if(collisionMeshIntersectionData != null)
			{
				// Global coords of camera-collision mesh intersection
				intersectionPoint = collisionMeshIntersectionData.object.localToGlobal(collisionMeshIntersectionData.point);
			
				// Debug line0---------------------------------------------------------------
							if(line0 != null)
								Globals.renderer.removeObject3D(line0, true);
							var linePoints:Vector.<Vector3D> = new Vector.<Vector3D>();
							linePoints.push(origin, intersectionPoint);
							line0 = WireFrame.createLinesList(linePoints, 0x0000FF, 1, 1);
							Globals.renderer.addObject3D(line0, true);			
							// Debug - mark intersection with blue sphere
							if(rutul != null)
								Globals.renderer.removeObject3D(rutul, true);
							rutul = new GeoSphere(20,5,false, new FillMaterial(0x0000FF, 0.85));
							rutul.x = intersectionPoint.x;
							rutul.y = intersectionPoint.y;
							rutul.z = intersectionPoint.z;
							Globals.renderer.addObject3D(rutul, true);
				//-----------------------------------------------------------------------------		
				
				// Calculate direction of ray from weapon fire output point
				// to the intersection point determined earlier
				origin = this.model.localToGlobal(_fireOriginPoint);
				direction = intersectionPoint.subtract(origin);
				direction.normalize();
				
				// Intersect calculated ray with bound boxes of all other units
				for each(var u:Entity in Globals.gameCore.ctents)
				{
					if(u != _unit)
					{
						if(u.model.boundBox.intersectRay(u.model.globalToLocal(origin), direction))
						{
							trace("Entity hit: " + u);
							hitUnits.push(u);
						}	
					}
				}
				
				// If some units were hit
				if(hitUnits.length > 0)
				{
					minHitDistance = Number.MAX_VALUE;
					
					for each(u in hitUnits)
					{
						var distance:Number = Vector3D.distance(origin, u.position);
						if(distance < minHitDistance)
						{
							unitToHit = u;
							minHitDistance = distance;
						}
					}
				}			
				
				// Intersect calculated ray with collision mesh
				collisionMeshIntersectionData = GameMap.currentMap.collisionMesh.intersectRay(origin, direction);			
				// Ignore hit units if terrain hitpoint is closer than closes hit unit			
				if(collisionMeshIntersectionData != null)
				{
					//trace("#2 Collision mesh was hit.");
					//trace("object: "+collisionMeshIntersectionData.object);
					if(collisionMeshIntersectionData.time < minHitDistance)
					{
						//trace("#2 Collision mesh prevented unit from being hit.");
					} else {
						if(unitToHit != null)
						{
							///trace("Unit really was hit.");
						}
					}
				} else {
					//trace("#2 Collision mesh was not hit?!");
				}
				
				// debug rutul------------------------------------------------------
							if(collisionMeshIntersectionData != null)
							{
								// Debug - mark intersection with blue sphere			
								if(rutul2 != null) 
									Globals.renderer.removeObject3D(rutul2, true);
								rutul2 = new GeoSphere(20,5,false, new FillMaterial(0x3355FF, 0.85));
								rutul2.x = collisionMeshIntersectionData.object.localToGlobal(collisionMeshIntersectionData.point).x;
								rutul2.y = collisionMeshIntersectionData.object.localToGlobal(collisionMeshIntersectionData.point).y;
								rutul2.z = collisionMeshIntersectionData.object.localToGlobal(collisionMeshIntersectionData.point).z;
								Globals.renderer.addObject3D(rutul2, true);
							}
							
							if(collisionMeshIntersectionData != null)
							{
								// Debug line
								if(line != null) Globals.renderer.removeObject3D(line, true);
								linePoints = new Vector.<Vector3D>();
								linePoints.push(this.model.localToGlobal(_fireOriginPoint), collisionMeshIntersectionData.object.localToGlobal(collisionMeshIntersectionData.point));
								line = WireFrame.createLinesList(linePoints, 0x00FF00, 1, 1);
								Globals.renderer.addObject3D(line, true);				
							}
				//--------------------------------------------------------------
			} else {
				trace("No intersection with collision mesh.");
			}
		}
		
		private var rutul3:GeoSphere;
		
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
		 * Shoul be called when the object  is no longer needed.
		 */
		public override function dispose():void
		{
			super.dispose();
		}
	}
}