package net.akimirksnis.delta.game.collisions
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	use namespace delta_internal;

	public class CollisionOctree
	{
		private static var _instance:CollisionOctree = new CollisionOctree(SingletonLock);
		
		private var root:Partition;
		private var wireframeRoot:Object3D;
		
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
			var minGlobal:Vector3D = map.collisionMesh.localToGlobal(new Vector3D(mapBB.minX, mapBB.minY, mapBB.minZ));
			
			// Calculate root partition side length 
			var rootEdgeLength:Number = Math.max(
				mapBB.maxX - mapBB.minX,
				mapBB.maxY - mapBB.minY,
				mapBB.maxZ - mapBB.minZ);		
			
			// Reset partitioning
			// Position root partition to have its front left bottom corner
			// at the global position of (minX, minY, minZ) of map bound box
			root = new Partition(
				minGlobal.x,
				minGlobal.y,
				minGlobal.z,
				minGlobal.x + rootEdgeLength,
				minGlobal.y + rootEdgeLength,
				minGlobal.z + rootEdgeLength
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
			
			if(Globals.DEBUG_MODE)
			{
				generateWireframes();
			}
		}
		
		/*---------------------------
		Debug helpers
		---------------------------*/
		
		/**
		 * Generates wireframes for octree partitions.
		 */
		private function generateWireframes():void
		{
			root.generateWireframe(GameMap.currentMap.wireframeRoot);
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
		
		/**
		 * Indicates octree wireframe visibility.
		 */
		public function get wireframeVisible():Boolean
		{			
			if(wireframeRoot != null)
			{
				return wireframeRoot.visible;
			}
			
			return false;
		}
		public function set wireframeVisible(value:Boolean):void
		{			
			if(wireframeRoot != null)
			{
				wireframeRoot.visible = value;
			}		
		}
	}
}

class SingletonLock {}