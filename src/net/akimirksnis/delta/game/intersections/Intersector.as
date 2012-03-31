package net.akimirksnis.delta.game.intersections
{
	import alternativa.engine3d.core.RayIntersectionData;
	import alternativa.engine3d.core.VertexAttributes;
	import alternativa.engine3d.objects.Mesh;	
	import net.akimirksnis.delta.game.utils.*;	
	import flash.geom.Vector3D;
	
	public class Intersector
	{
		public static const PRECISION:Number = 0.001;
		
		public static function intesectSegment(mesh:Mesh, segment:Segment, skipIntersectionsAtExactEnd:Boolean = false):RayIntersectionData
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
	}
}