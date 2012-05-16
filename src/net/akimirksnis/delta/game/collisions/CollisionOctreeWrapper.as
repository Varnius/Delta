package net.akimirksnis.delta.game.collisions
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	use namespace delta_internal;

	/**
	 * Collision octree wrapper. Includes some performance optimisations and should be used instead of raw octree.
	 */
	public class CollisionOctreeWrapper
	{		
		delta_internal static var rootPartitions:Vector.<Partition> = new Vector.<Partition>();
		private static var instances:int = 0;
		private static var instanceNum:int;		
		
		// Use a dictionary for quickly accessing partition that holds
		// needed collider without recursively searching the whole tree
		private var collidersAndPartitions:Dictionary = new Dictionary();
		
		// Debug
		private var wireframeRoot:Object3D;
		
		/**
		 * Class constructor.
		 */
		public function CollisionOctreeWrapper(source:Mesh = null)
		{		
			trace("[CollisionOctree] > Generating octree");
			instanceNum = instances;			
			
			var rootPartition:Partition;
			
			if(source != null)
			{
				// Get bound box of the source mesh in global space
				var sourceBB:BoundBox = Utils.getConcatenatedBoundBox(source);
				var minGlobal:Vector3D = source.localToGlobal(new Vector3D(sourceBB.minX, sourceBB.minY, sourceBB.minZ));
				
				// Calculate root partition side length 
				var rootEdgeLength:Number = Math.max(
					sourceBB.maxX - sourceBB.minX,
					sourceBB.maxY - sourceBB.minY,
					sourceBB.maxZ - sourceBB.minZ);		
				
				// Reset partitioning
				// Position root partition to have its front left bottom corner at the
				// global position of (minX, minY, minZ) of source mesh bound box
				rootPartition = new Partition(
					minGlobal.x,
					minGlobal.y,
					minGlobal.z,
					minGlobal.x + rootEdgeLength,
					minGlobal.y + rootEdgeLength,
					minGlobal.z + rootEdgeLength,
					collidersAndPartitions,
					instanceNum
				);		
			} else {
				rootPartition = new Partition(
					0,
					0,
					0,
					100,
					100,
					100,
					collidersAndPartitions,
					instanceNum
				);					
			}
			
			rootPartition.name = "partition-root";
			rootPartitions[instances] = rootPartition;
			
			if(Globals.DEBUG_MODE)
			{
				wireframeRoot = new Object3D();
				wireframeRoot.name = "octree-wireframe-root" + instances;
				wireframeRoot.visible = false;
				GameMap.currentMap.wireframeRoot.addChild(wireframeRoot);
				rootPartition.wireframeRoot = wireframeRoot;
			}
			
			instances++;
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Checks for collider position changes and updates octree accordingly.
		 * 
		 * @param collider Collider to check.
		 */
		public function updateByCollider(collider:Mesh):void
		{		
			Partition(collidersAndPartitions[collider]).updateColliderPosition(collider);
		}
		
		/**
		 * Adds a collider to the octree.
		 * 
		 * @param collider Collider to add.
		 */
		public function addCollider(collider:Mesh):void
		{		
			rootPartitions[instanceNum].addCollider(collider);
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Indicates octree wireframe visibility.
		 */
		public function get wireframeVisible():Boolean
		{			
			if(Globals.DEBUG_MODE)
			{
				return wireframeRoot.visible;
			}
			
			return false;
		}
		public function set wireframeVisible(value:Boolean):void
		{			
			if(Globals.DEBUG_MODE)
			{
				wireframeRoot.visible = value;
			}		
		}
	}
}