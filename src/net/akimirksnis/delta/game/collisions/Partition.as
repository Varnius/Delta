package net.akimirksnis.delta.game.collisions
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.Renderer3D;

	use namespace delta_internal;
	
	/**
	 * A class representing a partition in an octree.
	 */
	public class Partition
	{
		public static const MAX_OBJECTS_PER_PARTITION:int = 1;
		//private static const MIN_OBJECTS_PER_PARTITION:int = 5;		
		
		private var _partitions:Vector.<Partition> = new Vector.<Partition>();
		private var _colliders:Vector.<Mesh> = new Vector.<Mesh>();	
		private var _split:Boolean = false;		
		
		private var _minX:Number;
		private var _minY:Number;
		private var _minZ:Number;
		private var _maxX:Number;
		private var _maxY:Number;
		private var _maxZ:Number;
		private var _widthX:Number;
		private var _widthY:Number;
		private var _widthZ:Number;		
		private var newMiddleX:Number;
		private var newMiddleY:Number;
		private var newMiddleZ:Number;
		private var temp:Vector3D = new Vector3D();
		
		private var wireframe:WireFrame;
		
		/**
		 * Class constructor.
		 */
		public function Partition(minX:Number, minY:Number, minZ:Number, maxX:Number, maxY:Number, maxZ:Number)
		{
			_minX = minX;
			_minY = minY;
			_minZ = minZ;
			_maxX = maxX;
			_maxY = maxY;
			_maxZ = maxZ;
			
			// Calculate dimensions of this partition
			_widthX = _maxX - _minX;
			_widthY = _maxY - _minY;
			_widthZ = _maxZ - _minZ;
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
			if(_colliders.length < MAX_OBJECTS_PER_PARTITION)
			{
				_colliders.push(collider);
			} else {
				
				// Create 8 new partitions
				
				newMiddleX = minX + (maxX - minX) / 2;
				newMiddleY = minY + (maxY - minY) / 2;
				newMiddleZ = minZ + (maxZ - minZ) / 2;				
				
				// Up
				
				// Up front left
				_partitions.push(
					new Partition(minX, minY, newMiddleZ, newMiddleX, newMiddleY, maxZ)
				);
				
				// Up front right
				_partitions.push(
					new Partition( newMiddleX, minY, newMiddleZ, maxX, newMiddleY, maxZ)
				);
				
				// Up back left
				_partitions.push(
					new Partition(minX, newMiddleY,	newMiddleZ,	newMiddleX,	maxY, maxZ)
				);
				
				// Up back right
				_partitions.push(
					new Partition(newMiddleX, newMiddleY, newMiddleZ, maxX,	maxY, maxZ)
				);
				
				// Bottom		
				
				// Bottom front left
				_partitions.push(
					new Partition(minX, minY, minZ, newMiddleX,	newMiddleY, newMiddleZ)
				);
				
				// Bottom front right
				_partitions.push(
					new Partition(newMiddleX, minY,	minZ, maxX,	newMiddleY,	newMiddleZ)
				);
				
				// Bottom back left
				_partitions.push(
					new Partition(minX,	newMiddleY,	minZ, newMiddleX, maxY, newMiddleZ)
				);
				
				// Bottom back right
				_partitions.push(
					new Partition(newMiddleX, newMiddleY, minZ,	maxX, maxY,	newMiddleZ)
				);
				
				// Assign colliders to new partitions (if fits)				
				for each(var c:Mesh in _colliders)
				{
					for each(var p:Partition in _partitions)
					{
						// If collider fits into one of the new partitions assign
						// it to that partition and remove from this one
						if(p.fits(c))
						{
							p.addCollider(c);
							// todo: optimize?
							_colliders.splice(_colliders.indexOf(c), 1);
							break;
						}
					}
				}
				
				_split = true;				
			}
		}
		
		/**
		 * Removes collider.
		 * 
		 * @param collider Collider to remove.
		 */
		public function removeCollider(collider:Mesh):void
		{
			// todo
		}
		
		/**
		 * Should be called to update octree when position of the collider changes.
		 *
		 * @param collider Source object.
		 */
		public function updateByObject(collider:Mesh):void
		{
			
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
		 * Cleans up outer references.
		 */
		public function dispose():void
		{
			_colliders = null;
			
			for each(var p:Partition in _partitions)
			{
				p.dispose();
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
		delta_internal function generateWireframe(root:Object3D):void
		{
			// Skip this partition if it`s split
			if(_split)
			{
				for each(var p:Partition in _partitions)
				{
					p.generateWireframe(root);
				}
				
				return;
			}
			
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
			root.addChild(wireframe);
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/

		/**
		 * Child partitions.
		 */
		public function get partitions():Vector.<Partition>
		{
			return _partitions;
		}
		
		/**
		 * Child objects.
		 */
		public function get colliders():Vector.<Mesh>
		{
			return _colliders;
		}
		
		/**
		 * Indicates whether the partition has been already split.
		 */
		public function get split():Boolean
		{
			return _split;
		}

		public function get minX():Number
		{
			return _minX;
		}
		
		public function get minY():Number
		{
			return _minY;
		}
		
		public function get minZ():Number
		{
			return _minZ;
		}
		
		public function get maxX():Number
		{
			return _maxX;
		}
		
		public function get maxY():Number
		{
			return _maxY;
		}
		
		public function get maxZ():Number
		{
			return _maxZ;
		}
		
		public function get widthX():Number
		{
			return _widthX;
		}
		
		public function get widthY():Number
		{
			return _widthY;
		}
		
		public function get widthZ():Number
		{
			return _widthZ;
		}
	}
}