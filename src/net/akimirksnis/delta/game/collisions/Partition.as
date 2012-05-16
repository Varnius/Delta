package net.akimirksnis.delta.game.collisions
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.Renderer3D;
	import net.akimirksnis.delta.game.utils.Globals;

	use namespace delta_internal;
	
	/**
	 * A class representing a partition in an octree.
	 */
	public class Partition
	{
		// Split partition if there are defined number of colliders
		private static const MAX_COLLIDERS_PER_PARTITION:int = 2;
		
		// Merge partition if there are defined number of colliders
		private static const MIN_COLLIDERS_PER_PARTITION:int = 1;
		
		delta_internal var instanceNum:int;
		delta_internal var partitions:Vector.<Partition> = new Vector.<Partition>();
		delta_internal var colliders:Vector.<Mesh> = new Vector.<Mesh>();	
		delta_internal var isSplit:Boolean = false;
		delta_internal var parent:Partition;		
		delta_internal var minX:Number;
		delta_internal var minY:Number;
		delta_internal var minZ:Number;
		delta_internal var maxX:Number;
		delta_internal var maxY:Number;
		delta_internal var maxZ:Number;
		
		private var edgeLength:Number;		
		private var newMiddleX:Number;
		private var newMiddleY:Number;
		private var newMiddleZ:Number;		
		private var temp:Vector3D = new Vector3D();		
		private var collidersAndPartitions:Dictionary;		
		
		// Debug
		delta_internal var name:String = "unnamed";		
		delta_internal var wireframeRoot:Object3D;
		private var wireframe:WireFrame;
		
		/**
		 * Class constructor.
		 */
		public function Partition(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number, collidersAndPartitions:Dictionary, instanceNum:int, parent:Partition = null)
		{			
			this.minX = minX;
			this.minY = minY;
			this.minZ = minZ;
			this.maxX = maxX;
			this.maxY = maxY;
			this.maxZ = maxZ;

			// Calculate dimensions of this partition
			edgeLength = maxX - minX;
			
			this.collidersAndPartitions = collidersAndPartitions;			
			this.parent = parent;
			this.instanceNum = instanceNum;
			
			if(Globals.DEBUG_MODE && parent != null)
			{
				this.wireframeRoot = parent.wireframeRoot;
			}			
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Adds collider to the partition. Partition splits in case number
		 * of added objects is greater than MAX_OBJECTS_PER_PARTITION constant.
		 */
		delta_internal function addCollider(collider:Mesh):void
		{
			var addedDeeper:Boolean = false;
			
			// Check if collider fits into this partition. If don`t
			// fit, then grow the tree until the collider is inside
			if(parent == null && !fits(collider))
			{	
				grow(collider);
				return;
			}			
			
			if(isSplit)
			{
				// See if collider fits into any child partitions
				for each(var p:Partition in partitions)
				{
					if(p.fits(collider))
					{
						p.addCollider(collider);
						
						if(Globals.DEBUG_MODE)
						{
							generateWireframe();
						}
						
						addedDeeper = true;
					}						
				}
				
				if(!addedDeeper)
				{
					// Attach to this partition otherwise
					colliders.push(collider);
					collidersAndPartitions[collider] = this;
				}
				
			} else {
				colliders.push(collider);
				collidersAndPartitions[collider] = this;
				
				// Split partition when split limit is reached
				if(colliders.length >= MAX_COLLIDERS_PER_PARTITION)
				{
					split();
				}
			}
			
			// Shrink octree if possible
			if(parent == null)
			{
				shrink();
			}			
			
			if(Globals.DEBUG_MODE)
			{
				generateWireframe();
			}
		}
		
		/**
		 * Removes collider.
		 * 
		 * @param collider Collider to remove.
		 */
		public function removeCollider(collider:Mesh):void
		{
			colliders.splice(colliders.indexOf(collider), 1);			
			
			// Merge partitions if number of children is less than threshold
			if(getChildCount() <= MIN_COLLIDERS_PER_PARTITION)
			{
				merge();
			}
			
			if(Globals.DEBUG_MODE)
			{
				generateWireframe();
			}		
		}
		
		/**
		 * Returns string representation of octree hierarchy.
		 * 
		 * @return Octree hierarchy as string.
		 */
		public function getOctreeHierarchyAsString(spacer:String = ""):String
		{
			var result:String = "";
			
			result += spacer + this + " Children: " + ((colliders.length > 0) ? colliders : "none") + "\n";
			
			for each(var p:Partition in partitions)
			{
				result += p.getOctreeHierarchyAsString(spacer + "      ");
			}
			
			return result;
		}
		
		/*---------------------------
		Internal methods
		---------------------------*/
		
		/**
		 * Should be called to update octree when position of the collider changes.
		 *
		 * @param collider Source object.
		 */
		delta_internal function updateColliderPosition(collider:Mesh):void
		{
			// If collider do not fit into this partition anymore
			if(!fits(collider))
			{
				// Save reference to root beforehand, since this partition may be disposed after unsplit
				var root:Partition = this.root;				
				removeCollider(collider);
				
				// Re-add collider again
				root.addCollider(collider);				
			} else {
				// Place collider deeper if possible
				// Such possibility can occur if the collider has passed division line recently and
				// has been put to the higher in the hierarchy since it didn`t fit anywhere deeper				
				for each(var p:Partition in partitions)
				{
					if(p.fits(collider))
					{						
						p.addCollider(collider);
						removeCollider(collider);
						break;
					}					
				}
			}
			
			if(Globals.DEBUG_MODE)
			{
				generateWireframe();
			}
		}
		
		/**
		 * Checks whether a collider fits into this
		 * partition. Collider`s bound box is checked.
		 * 
		 * @param collider Collider.
		 * @return True if collider fits, false otherwise.
		 */
		delta_internal function fits(collider:Mesh):Boolean
		{
			temp.setTo(collider.boundBox.minX, collider.boundBox.minY, collider.boundBox.minZ);
			temp.copyFrom(collider.localToGlobal(temp));
			
			var globalMinX:Number = temp.x;
			var globalMinY:Number = temp.y;
			var globalMinZ:Number = temp.z;
			
			temp.setTo(collider.boundBox.maxX, collider.boundBox.maxY, collider.boundBox.maxZ);
			temp.copyFrom(collider.localToGlobal(temp));
			
			var globalMaxX:Number = temp.x;
			var globalMaxY:Number = temp.y;
			var globalMaxZ:Number = temp.z;
			
			// Check x
			if( !(globalMinX >= minX && globalMinX < maxX &&
			      globalMaxX <= maxX && globalMaxX > minX) )
			{
				return false;
			}
			
			// Check y
			if( !(globalMinY >= minY && globalMinY < maxY &&
				globalMaxY <= maxY && globalMaxY > minY) )
			{
				return false;
			}
			
			// Check z
			if( !(globalMinZ >= minZ && globalMinZ < maxZ &&
				globalMaxZ <= maxZ && globalMaxZ > minZ) )
			{
				return false;
			}
			
			return true;			
		}
		
		/**
		 * Returns collider count for this partition and it`s subpartitions.
		 * 
		 * @return Number of children.
		 */
		delta_internal function getChildCount():int
		{
			var result:int = colliders.length;
			
			for each(var p:Partition in partitions)
			{
				result += p.getChildCount();
			}
			
			return result;
		}
		
		/**
		 * Get a list of colliders belonging to this and child partitions.
		 * 
		 * @param excludeTop Do not include colliders from the object which initiated the search.
		 * @return List of objects.
		 */
		delta_internal function getCollidersRecursively(excludeTop:Boolean = false):Vector.<Mesh>
		{
			var result:Vector.<Mesh> = new Vector.<Mesh>();
			
			if(!excludeTop)
			{
				result = result.concat(colliders);
			}			
			
			for each(var p:Partition in partitions)
			{
				result = result.concat(p.getCollidersRecursively());
			}
			
			return result;
		}	
		
		/**
		 * Cleans up outer references.
		 */
		delta_internal function dispose():void
		{			
			for each(var p:Partition in partitions)
			{
				p.dispose();
			}
			
			colliders = null;
			parent = null;
			partitions = null;
			
			// Get rid of any existing wireframes
			if(wireframe != null)
			{
				wireframe.parent.removeChild(wireframe);
				Renderer3D.instance.disposeResources(wireframe.getResources());				
			}
		}		
		
		/*---------------------------
		Split / merge
		---------------------------*/
		
		/**
		 * Splits this partition into new 8 partitions.
		 */
		delta_internal function split():void
		{
			// Create 8 new partitions
			
			newMiddleX = minX + (maxX - minX) / 2;
			newMiddleY = minY + (maxY - minY) / 2;
			newMiddleZ = minZ + (maxZ - minZ) / 2;				
			
			// Up
			
			// Up front left
			partitions.push(
				new Partition(minX, minY, newMiddleZ, newMiddleX, newMiddleY, maxZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "up-front-left     ";
			
			// Up front right
			partitions.push(
				new Partition( newMiddleX, minY, newMiddleZ, maxX, newMiddleY, maxZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "up-front-right    ";
			
			// Up back left
			partitions.push(
				new Partition(minX, newMiddleY,	newMiddleZ,	newMiddleX,	maxY, maxZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "up-back-left      ";
			
			// Up back right
			partitions.push(
				new Partition(newMiddleX, newMiddleY, newMiddleZ, maxX,	maxY, maxZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "up-back-right     ";
			
			// Bottom		
			
			// Bottom front left
			partitions.push(
				new Partition(minX, minY, minZ, newMiddleX,	newMiddleY, newMiddleZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "bottom-front-left ";
			
			// Bottom front right
			partitions.push(
				new Partition(newMiddleX, minY,	minZ, maxX,	newMiddleY,	newMiddleZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "bottom-front-right";
			
			// Bottom back left
			partitions.push(
				new Partition(minX,	newMiddleY,	minZ, newMiddleX, maxY, newMiddleZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "bottom-back-left  ";			
			
			// Bottom back right
			partitions.push(
				new Partition(newMiddleX, newMiddleY, minZ,	maxX, maxY,	newMiddleZ, collidersAndPartitions, instanceNum, this)
			);
			partitions[partitions.length - 1].name = "bottom-back-right ";

			// Assign colliders to new partitions (if fits)				
			for(var i:int = colliders.length - 1; i >= 0; i--)
			{				
				for each(var p:Partition in partitions)
				{
					// If collider fits into one of the new partitions assign
					// it to that partition and remove from this one
					if(p.fits(colliders[i]))
					{
						p.addCollider(colliders[i]);
						colliders.splice(i, 1);
						break;
					}
				}
			}
			
			isSplit = true;
		}
		
		/**
		 * Removes child partitions and moves child objects up to first available partition.
		 */
		private function merge():void
		{
			// Merge partitions if number of children is less than threshold
			if(parent != null && parent.getChildCount() <= MIN_COLLIDERS_PER_PARTITION)
			{
				parent.merge();
			} else {
				var tmpColliders:Vector.<Mesh> = getCollidersRecursively(true);
				
				// Dispose child partitions
				for each(var p:Partition in partitions)
				{
					p.dispose();
				}
				
				partitions.length = 0;
				isSplit = false;
				
				// Re-add all colliders
				for each(var collider:Mesh in tmpColliders)
				{
					addCollider(collider);
				}				
			}
		}
		
		/*---------------------------
		Grow / shrink
		---------------------------*/
		
		/**
		 * Grows octree in case there are object outside its bounds.
		 * 
		 * @param collider Collider outside octree bounds.
		 */
		private function grow(collider:Mesh):void
		{		
			var colliderMinGlobal:Vector3D = collider.localToGlobal(new Vector3D(collider.boundBox.minX, collider.boundBox.minY, collider.boundBox.minZ));
			
			// Determine the position of new root partition
			var rootMinX:Number = Math.abs(colliderMinGlobal.x - minX) < Math.abs(colliderMinGlobal.x - maxX) ? minX - edgeLength : minX;
			var rootMinY:Number = Math.abs(colliderMinGlobal.y - minY) < Math.abs(colliderMinGlobal.y - maxY) ? minY - edgeLength : minY;
			var rootMinZ:Number = Math.abs(colliderMinGlobal.z - minZ) < Math.abs(colliderMinGlobal.z - maxZ) ? minZ - edgeLength : minZ;
			var rootEdgeLength:Number = edgeLength * 2;
			
			// Create new root partition
			var newRoot:Partition = new Partition(
				rootMinX,
				rootMinY,
				rootMinZ,
				rootMinX + rootEdgeLength,
				rootMinY + rootEdgeLength,
				rootMinZ + rootEdgeLength,
				collidersAndPartitions,
				instanceNum
			);
			parent = newRoot;
			newRoot.name = "newRoot";			
			
			if(Globals.DEBUG_MODE)
			{
				newRoot.wireframeRoot = wireframeRoot;
			}
			
			CollisionOctreeWrapper.rootPartitions[instanceNum] = newRoot;
			
			newRoot.split();
			
			// Replace one of new root partition child partition with this one
			for(var i:int = 0; i < newRoot.partitions.length; i++)
			{
				if(newRoot.partitions[i].minX == minX && newRoot.partitions[i].minY == minY && newRoot.partitions[i].minZ == minZ)
				{
					newRoot.partitions.splice(i, 1, this);
					break;
				}
			}
			
			// May initiate another call to grow()
			newRoot.addCollider(collider);
		}
		
		/**
		 * Shrinks octree, if possible.
		 */
		delta_internal function shrink():void
		{
			// Shrink octree if root partition contains only one partition that has children
			if(colliders.length == 0)
			{
				var numNonEmptyPartitions:int = 0;
				var index:int, i:int;				
				
				for(i = 0; i < partitions.length; i++)
				{
					if(partitions[i].getChildCount() > 0)
					{
						numNonEmptyPartitions++;
						index = i;
					}
				}
				
				// Shrink
				if(numNonEmptyPartitions == 1)
				{
					var newRoot:Partition = partitions[index];
					
					newRoot.parent = null;
					CollisionOctreeWrapper.rootPartitions[instanceNum] = newRoot;					
					
					// Dispose all partitions (except the one selected as new root)
					for(i = 0; i < partitions.length; i++)
					{
						if(i != index)
						{
							partitions[i].dispose();
						}
					}
					
					partitions.length = 0;
					dispose();
					
					if(Globals.DEBUG_MODE)
					{
						newRoot.generateWireframe();
					}
					
					newRoot.shrink();
				}
			}
		}
		
		/*---------------------------
		Debug helpers
		---------------------------*/
		
		/**
		 * Generates wireframe of partition or its children.
		 * 
		 * @param Root object to attach created wireframes to.
		 */
		delta_internal function generateWireframe():void
		{			
			// Skip this partition if it`s split
			if(isSplit)
			{
				for each(var p:Partition in partitions)
				{
					p.generateWireframe();
				}
				
				return;
			}
			
			if(wireframe == null)
			{
				// Generate set of points for wireframe
				var points:Vector.<Vector3D> = new Vector.<Vector3D>();
				points.push(
					new Vector3D(minX, minY, minZ),
					new Vector3D(maxX, minY, minZ),
					new Vector3D(maxX, maxY, minZ),
					new Vector3D(minX, maxY, minZ),
					new Vector3D(minX, minY, minZ),
					new Vector3D(minX, minY, maxZ),
					new Vector3D(maxX, minY, maxZ),
					new Vector3D(maxX, maxY, maxZ),
					new Vector3D(minX, maxY, maxZ),
					new Vector3D(minX, minY, maxZ),
					new Vector3D(minX, maxY, maxZ),
					new Vector3D(minX, maxY, minZ),
					new Vector3D(minX, maxY, maxZ),
					new Vector3D(maxX, maxY, maxZ),
					new Vector3D(maxX, maxY, minZ),
					new Vector3D(maxX, maxY, maxZ),
					new Vector3D(maxX, minY, maxZ),
					new Vector3D(maxX, minY, minZ)
				);
				
				wireframe = WireFrame.createLineStrip(points, 0xFFFFFF, 1, 1);
				Renderer3D.instance.uploadResources(wireframe.getResources());
				wireframeRoot.addChild(wireframe);
			}			
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Root partition of the octree.
		 */
		public function get root():Partition
		{
			var currentPartition:Partition = this;
			
			// Go up the hierarchy until we find root partition
			while(currentPartition.parent != null)
			{
				currentPartition = currentPartition.parent;
			}
			
			return currentPartition;
		}
		
		/**
		 * Returns string representation of this object.
		 * 
		 * @return String representation of this object.
		 */
		public function toString():String
		{
			return "[Partition " + name + "]";
		}
	}
}