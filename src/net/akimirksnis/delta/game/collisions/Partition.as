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
		public static const MAX_COLLIDERS_PER_PARTITION:int = 1;
		private static const MIN_COLLIDERS_PER_PARTITION:int = 1;		
		
		private var _partitions:Vector.<Partition> = new Vector.<Partition>();
		private var _colliders:Vector.<Mesh> = new Vector.<Mesh>();	
		private var _split:Boolean = false;		
		
		private var minX:Number;
		private var minY:Number;
		private var minZ:Number;
		private var maxX:Number;
		private var maxY:Number;
		private var maxZ:Number;
		private var _widthX:Number;
		private var _widthY:Number;
		private var _widthZ:Number;		
		private var newMiddleX:Number;
		private var newMiddleY:Number;
		private var newMiddleZ:Number;
		private var temp:Vector3D = new Vector3D();
		
		private var wireframe:WireFrame;
		private var collidersAndPartitions:Dictionary;
		delta_internal var parent:Partition;
		delta_internal var wireframeRoot:Object3D;
		
		public var name:String = "unnamed";
		
		/**
		 * Class constructor.
		 */
		public function Partition(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number, collidersAndPartitions:Dictionary, parent:Partition = null)
		{			
			this.minX = minX;
			this.minY = minY;
			this.minZ = minZ;
			this.maxX = maxX;
			this.maxY = maxY;
			this.maxZ = maxZ;

			// Calculate dimensions of this partition
			_widthX = maxX - minX;
			_widthY = maxY - minY;
			_widthZ = maxZ - minZ;
			
			this.collidersAndPartitions = collidersAndPartitions;			
			this.parent = parent;
			
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
		public function addCollider(collider:Mesh):void
		{
			if(_partitions.length > 0)
			{
				// See if fits into any child partition
				for each(var p:Partition in _partitions)
				{
					if(p.fits(collider))
					{
						p.addCollider(collider);
						return;
					}						
				}		
				
				// Attach to this partition otherwise
				_colliders.push(collider);
				collidersAndPartitions[collider] = this;
			} else {
				_colliders.push(collider);
				collidersAndPartitions[collider] = this;
				
				// Split partition when split limit is reached
				if(_colliders.length > MAX_COLLIDERS_PER_PARTITION)
				{
					split();
				}
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
			_colliders.splice(_colliders.indexOf(collider), 1);
			
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
		 * Should be called to update octree when position of the collider changes.
		 *
		 * @param collider Source object.
		 */
		public function updateColliderPosition(collider:Mesh):void
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
				for each(var p:Partition in _partitions)
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
		public function fits(collider:Mesh):Boolean
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
		public function getChildCount():int
		{
			var result:int = _colliders.length;
			
			for each(var p:Partition in _partitions)
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
		public function getCollidersRecursively(excludeTop:Boolean = false):Vector.<Mesh>
		{
			var result:Vector.<Mesh> = new Vector.<Mesh>();
			
			if(!excludeTop)
			{
				result = result.concat(_colliders);
			}			
			
			for each(var p:Partition in _partitions)
			{
				result = result.concat(p.getCollidersRecursively());
			}
			
			return result;
		}
		
		/**
		 * Returns string representation of octree hierarchy.
		 * 
		 * @return Octree hierarchy as string.
		 */
		public function getOctreeHierarchyAsString(spacer:String = ""):String
		{
			var result:String = "";
			
			result += spacer + this + " Children: " + ((_colliders.length > 0) ? _colliders : "none") + "\n";
			
			for each(var p:Partition in _partitions)
			{
				result += p.getOctreeHierarchyAsString(spacer + "      ");
			}
			
			return result;
		}
		
		/**
		 * Cleans up outer references.
		 */
		public function dispose():void
		{			
			for each(var p:Partition in _partitions)
			{
				p.dispose();
			}
			
			_colliders = null;
			parent = null;
			_partitions = null;
			
			// Get rid of any existing wireframes
			if(wireframe != null)
			{
				wireframe.parent.removeChild(wireframe);
				Renderer3D.instance.disposeResources(wireframe.getResources());				
			}
		}		
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/**
		 * Splits this partition into new 8 partitions.
		 */
		private function split():void
		{
			// Create 8 new partitions
			
			newMiddleX = minX + (maxX - minX) / 2;
			newMiddleY = minY + (maxY - minY) / 2;
			newMiddleZ = minZ + (maxZ - minZ) / 2;				
			
			// Up
			
			// Up front left
			_partitions.push(
				new Partition(minX, minY, newMiddleZ, newMiddleX, newMiddleY, maxZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "up-front-left     ";
			
			// Up front right
			_partitions.push(
				new Partition( newMiddleX, minY, newMiddleZ, maxX, newMiddleY, maxZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "up-front-right    ";
			
			// Up back left
			_partitions.push(
				new Partition(minX, newMiddleY,	newMiddleZ,	newMiddleX,	maxY, maxZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "up-back-left      ";
			
			// Up back right
			_partitions.push(
				new Partition(newMiddleX, newMiddleY, newMiddleZ, maxX,	maxY, maxZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "up-back-right     ";
			
			// Bottom		
			
			// Bottom front left
			_partitions.push(
				new Partition(minX, minY, minZ, newMiddleX,	newMiddleY, newMiddleZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "bottom-front-left ";
			
			// Bottom front right
			_partitions.push(
				new Partition(newMiddleX, minY,	minZ, maxX,	newMiddleY,	newMiddleZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "bottom-front-right";
			
			// Bottom back left
			_partitions.push(
				new Partition(minX,	newMiddleY,	minZ, newMiddleX, maxY, newMiddleZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "bottom-back-left  ";			
			
			// Bottom back right
			_partitions.push(
				new Partition(newMiddleX, newMiddleY, minZ,	maxX, maxY,	newMiddleZ, collidersAndPartitions, this)
			);
			_partitions[_partitions.length - 1].name = "bottom-back-right ";

			// Assign colliders to new partitions (if fits)				
			for(var i:int = _colliders.length - 1; i >= 0; i--)
			{				
				for each(var p:Partition in _partitions)
				{
					// If collider fits into one of the new partitions assign
					// it to that partition and remove from this one
					if(p.fits(_colliders[i]))
					{
						p.addCollider(_colliders[i]);
						_colliders.splice(i, 1);
						break;
					}
				}
			}
			
			_split = true;
		}
		
		/**
		 * Removes child partitions and moves child objects up to first available partition.
		 */
		private function merge():void
		{
			// Unsplit partitions if number of children is less than threshold
			if(parent.getChildCount() <= MIN_COLLIDERS_PER_PARTITION)
			{
				parent.merge();
			} else {
				var colliders:Vector.<Mesh> = getCollidersRecursively(true);
				
				// Dispose child partitions
				for each(var p:Partition in _partitions)
				{
					p.dispose();
				}
				
				_partitions.length = 0;
				_split = false;
				
				// Re-add all colliders
				for each(var collider:Mesh in colliders)
				{
					addCollider(collider);
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
			if(_split)
			{
				for each(var p:Partition in _partitions)
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
		
		public function toString():String
		{
			return "[Partition " + name + "]";
		}
	}
}