package net.akimirksnis.delta.game.collisions
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	use namespace delta_internal;

	public class CollisionOctreeWrapper
	{		
		private static var instances:int = 0;		
		private var _rootPartition:Partition;
		private var wireframeRoot:Object3D;
		
		// Use a dictionary for quickly accessing partition that holds
		// needed collider without recursively searchin the whole octree
		private var collidersAndPartitions:Dictionary = new Dictionary();
		
		/**
		 * Class constructor.
		 */
		public function CollisionOctreeWrapper(source:Mesh = null)
		{			
			trace("[CollisionOctree] > Generating octree");
			
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
				_rootPartition = new Partition(
					minGlobal.x,
					minGlobal.y,
					minGlobal.z,
					minGlobal.x + rootEdgeLength,
					minGlobal.y + rootEdgeLength,
					minGlobal.z + rootEdgeLength,
					collidersAndPartitions
				);		
			} else {
				_rootPartition = new Partition(
					0,
					0,
					0,
					100,
					100,
					100,
					collidersAndPartitions
				);					
			}
			
			_rootPartition.name = "partition-root";				
			
			if(Globals.DEBUG_MODE)
			{
				wireframeRoot = new Object3D();
				wireframeRoot.name = "octree-wireframe-root" + instances;
				// todo
				//wireframeRoot.visible = false;
				GameMap.currentMap.wireframeRoot.addChild(wireframeRoot);
				_rootPartition.wireframeRoot = wireframeRoot;
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
		public function updateColliderPosition(collider:Mesh):void
		{		
			Partition(collidersAndPartitions[collider]).updateColliderPosition(collider);	
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

		/**
		 * Root partition of the octree.
		 */
		public function get rootPartition():Partition
		{
			return _rootPartition;
		}
	}
}