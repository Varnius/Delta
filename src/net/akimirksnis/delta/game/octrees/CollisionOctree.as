package net.akimirksnis.delta.game.octrees
{
	import alternativa.engine3d.alternativa3d;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.CullingPlane;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.Resource;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	use namespace delta_internal;
	use namespace alternativa3d;

	/**
	 * Collision octree wrapper. Includes some performance optimisations and should be used instead of raw octree.
	 */
	public class CollisionOctree
	{
		delta_internal static var rootPartitions:Vector.<Partition> = new Vector.<Partition>();
		delta_internal static var splitLimits:Vector.<int> = new Vector.<int>();
		delta_internal static var mergeLimits:Vector.<int> = new Vector.<int>();
	
		private var instanceNum:int;		
		
		// Use a dictionary for quickly accessing partition that holds
		// needed collider without recursively searching the whole tree
		private var collidersAndPartitions:Dictionary = new Dictionary(true);
		
		// Debug
		private var wireframeRoot:Object3D;
		delta_internal static var wireframeColors:Array = [0xFFAE00, 0xFF008A];
		
		/**
		 * Class constructor.
		 */
		public function CollisionOctree(source:Object3D = null, splitLimit:int = 5, mergeLimit:int = 5)
		{			
			instanceNum = -1;
			
			// Search for possible gaps to fill in
			for(var i:int = 0; i < rootPartitions.length; i++)
			{
				if(rootPartitions[i] == null)
				{
					instanceNum = i;
				}
			}
			
			if(instanceNum == -1)
			{
				instanceNum = rootPartitions.length;	
			}					
			
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
					null,
					collidersAndPartitions,
					instanceNum,
				    CollisionOctree
				);		
			} else {
				rootPartition = new Partition(
					-250,
					-250,
					-250,
					250,
					250,
					250,
					null,
					collidersAndPartitions,
					instanceNum,
					CollisionOctree
				);					
			}
			rootPartition.name = "partition-root";
			rootPartitions[instanceNum] = rootPartition;
			
			splitLimits.push(splitLimit);
			mergeLimits.push(mergeLimit);		
			
			if(Globals.DEBUG_MODE)
			{
				wireframeRoot = new Object3D();
				wireframeRoot.name = "octree-wireframe-root" + instanceNum;
				wireframeRoot.visible = false;
				GameMap.currentMap.wireframeRoot.addChild(wireframeRoot);
				rootPartition.wireframeRoot = wireframeRoot;
			}
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Checks for collider position changes and updates octree accordingly.
		 * 
		 * @param collider Collider to check.
		 */
		public function updateByCollider(collider:Object3D):void
		{
  			Partition(collidersAndPartitions[collider]).updateColliderPosition(collider);
		}
		
		/**
		 * Adds a collider to the octree.
		 * 
		 * @param collider Collider to add.
		 */
		public function addCollider(collider:Object3D):void
		{		
			rootPartitions[instanceNum].addCollider(collider);
		}
		
		/**
		 * Removes a collider from the octree.
		 * 
		 * @param collider Collider to remove.
		 */
		public function removeCollider(collider:Object3D):void
		{		
			rootPartitions[instanceNum].removeCollider(collider);
		}
		
		/**
		 * Returns a list of potential colliders (filtered by bounding box position of the source).
		 * 
		 * @param source An Object3D which will be used to calculate nearby colliders.
		 * @return A list of potential colliders.
		 */
		public function getPotentialColliders(source:Object3D):Vector.<Object3D>
		{
			return rootPartitions[instanceNum].getPotentialColliders(source);
		}
		
		/**
		 * Returns a list of potential colliders (filtered by camera frustum).
		 * 
		 * @param frustum Camera frustum start plane.
		 * @return A list of potential colliders.
		 */
		public function getCollidersByFrustum(frustum:CullingPlane):Vector.<Object3D>
		{
			return rootPartitions[instanceNum].getCollidersByFrustum(frustum);
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
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		/**
		 * Clean up.
		 */
		public function dispose():void
		{			
			rootPartitions[instanceNum] = null;
			splitLimits[instanceNum] = null;
			mergeLimits[instanceNum] = null;
			collidersAndPartitions = null;
			
			// Get rid of wireframes
			if(Globals.DEBUG_MODE)
			{
				for each(var r:Resource in wireframeRoot.getResources(true))
				{
					r.dispose();
				}
			}
		}		
	}
}