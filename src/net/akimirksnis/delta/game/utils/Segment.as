package net.akimirksnis.delta.game.utils
{
	import flash.geom.Vector3D;

	public class Segment
	{
		public var origin:Vector3D, end:Vector3D
		
		public function Segment(origin:Vector3D, end:Vector3D)
		{
			this.origin = origin;
			this.end = end;
		}
		
		public function getUnitVector():Vector3D
		{
			var vec:Vector3D = end.subtract(origin);
			vec.normalize();
			return vec;
		}
		
		public function toString():String
		{
			return "Segment: " + origin + ", " + end;
		}
	}
}