package net.akimirksnis.delta.game.intersections
{
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.utils.*;
	
	/**
	 * Utility class for intersecting various objects.
	 */
	public class Intersector
	{
		public static const PRECISION:Number = 0.001;
		
		/**
		 * Intersects mesh with a segment.
		 * 
		 * @param mesh Mesh to intesect.
		 * @param segment Segment to use for intersecting.
		 * @param skipIntersectionAtExactEnd Skip intersections that happen at the exact end of a segment.
		 * return RayIntersectionData object.
		 */
		public static function intesectSegmentMesh(mesh:Mesh, segment:Segment, skipIntersectionsAtExactEnd:Boolean = false):RayIntersectionData
		{
			var intersectionData:RayIntersectionData;
			var direction:Vector3D = segment.getUnitVector();
			var diff:Number;
			
			intersectionData = mesh.intersectRay(segment.origin, direction);
			
			if(intersectionData != null)
			{
				//diff = Math.abs(intersectionData.time - Vector3D.distance(segment.origin, segment.end));
				if(skipIntersectionsAtExactEnd)
				{
					//if(intersectionData.time >= Vector3D.distance(segment.origin, segment.end))
					if(intersectionData.time - Vector3D.distance(segment.origin, segment.end) > -PRECISION)
					{
						intersectionData = null;
					}
				} else {
					//if(intersectionData.time > Vector3D.distance(segment.origin, segment.end))
					if(intersectionData.time - Vector3D.distance(segment.origin, segment.end) > PRECISION)
					{
						intersectionData = null;
					}
				}
			}
			
			return intersectionData;
		}
		
		/**
		 * Intersects plane with a ray.
		 * 
		 * @param planeNormal Normal of a plane.
		 * @param planePoint A point within a plane.
		 * @param linePoint A point within the ray.
		 * @param result Result vector that is filled after calculating intersection.
		 */
		public static function intersectLinePlane(planeNormal:Vector3D, planePoint:Vector3D, linePoint:Vector3D, result:Vector3D):Vector3D
		{			
			result.copyFrom(planeNormal);
			
			// Calculate distance from linePoint to plane intersection
			var d:Number = 
				(planePoint.x - linePoint.x) * planeNormal.x + 
				(planePoint.y - linePoint.y) * planeNormal.y + 
				(planePoint.z - linePoint.z) * planeNormal.z;
			
			result.scaleBy(d);
			result.incrementBy(linePoint);
			
			return result;
		}
	}
}