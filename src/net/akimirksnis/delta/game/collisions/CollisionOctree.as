package net.akimirksnis.delta.game.collisions
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.objects.Mesh;
	
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.utils.Utils;

	public class CollisionOctree
	{
		private static var _instance:CollisionOctree = new CollisionOctree(SingletonLock);
		
		private var root:Partition;
		
		/**
		 * Class constructor.
		 */
		public function CollisionOctree(lock:Class)
		{			
			if(lock != SingletonLock)
			{
				throw new Error("The class 'CollisionOctreeManager' is singleton. Use 'CollisionOctreeManager.instance'.");
			}
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Generates collision octree.
		 */
		public function generateOctree(map:GameMap):void
		{
			// Get bound box of the map collision meshin global space
			var mapBB:BoundBox = Utils.getConcatenatedBoundBox(map.collisionMesh);
			
			trace('mapBB', mapBB);
			
			// Calculate root partition side length 
			var rootEdgeLength:Number = Math.max(
				mapBB.maxX - mapBB.minX,
				mapBB.maxY - mapBB.minY,
				mapBB.maxZ - mapBB.minZ);		
			
			// Reset partitioning
			// Position root partition to have its front left bottom corner
			// at the global position of (minX, minY, minZ) of map bound box
			root = new Partition(
				mapBB.minX,
				mapBB.minY,
				mapBB.minZ,
				mapBB.minX + rootEdgeLength,
				mapBB.minY + rootEdgeLength,
				mapBB.minZ + rootEdgeLength
			);
			
			// Add all map colliders to the octree
			for each(var o:Mesh in Utils.getMeshHierachyAsVector(map.collisionMesh))
			{
				root.addCollider(o);
			}
			
			// Add all entity colliders to the octree
			for each(var e:Entity in map.entities)
			{
				if(!e.excludeFromCollisions)
				{
					root.addCollider(e.m);
				}				
			}
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Returns class instance.
		 */
		public static function get instance():CollisionOctree
		{			
			return _instance;
		}
	}
}

class SingletonLock {}