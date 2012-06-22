package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	
	import flash.events.Event;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.entities.DynamicEntity;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.StaticEntity;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.octrees.CollisionOctree;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	[Event(name="hierarchyChanged", type="net.akimirksnis.delta.game.core.GameMap")]
	public class GameMap extends Object3D
	{
		public static const HIERARCHY_CHANGED:String = "hierarchyChanged";
		
		public static const TERRAIN_MESH_NAME:String = "mesh-terrain-root";		
		public static const COLLISION_MESH_NAME:String = "mesh-collision-root";
		public static const GENERIC_MESH_COLOR:uint = 0x0000CC;
		public static const TERRAIN_MESH_COLOR:uint = 0x00CC00;
		public static const COLLISION_MESH_COLOR:uint = 0xCC0000;
		
		private static var _currentMap:GameMap;
		
		public var extension:String = "A3D";
		
		private var zeroVector:Vector3D = new Vector3D();
		
		// Used for terrain and other stationary objects/entities
		private var _staticCollisionOctree:CollisionOctree;
		
		// Used for moving entities
		private var _dynamicCollisionOctree:CollisionOctree;	
		private var _dynamicEntities:Vector.<Entity> = new Vector.<Entity>();		
		
		private var _mapMeshes:Vector.<Mesh> = new Vector.<Mesh>();		
		private var _mapObjects:Vector.<Object3D> = new Vector.<Object3D>();
		private var _rootLevelObjects:Vector.<Object3D>;
		private var _lights:Vector.<Light3D> = new Vector.<Light3D>();
		private var _entities:Vector.<Entity> = new Vector.<Entity>();
		private var _collisionMesh:Mesh;
		private var _terrainMesh:Mesh;
		private var _wireframeRoot:Object3D;
		private var _units:Vector.<Unit> = new Vector.<Unit>();
		
		/*---------------------------
		Debug
		---------------------------*/
		
		private var _terrainMeshWireframe:WireFrame;
		private var _collisionMeshWireframe:WireFrame;
		private var _genericWireframes:Object3D;
		
		/**
		 * Class constructor.
		 */
		public function GameMap()
		{
			super();
		}
		
		/*---------------------------
		Public methods
		---------------------------*/	
		
		/**
		 * Prepares map for use.
		 */
		public function init():void
		{
			_currentMap = this;
			
			// Add all root level objects except collision mesh
			for each(var o:Object3D in _rootLevelObjects)
			{
				if(o.name != COLLISION_MESH_NAME)
				{
					addChild(o);
				}
			}
			
			// Generate wireframe root
			if(Globals.DEBUG_MODE)
			{
				_wireframeRoot = new Object3D();
				_wireframeRoot.name = "wireframe-root";
				addChild(_wireframeRoot);
			}
			
			/*---------------------------
			Handle terrain mesh
			---------------------------*/
			
			_terrainMesh = Mesh(getObjectByName(TERRAIN_MESH_NAME));
			
			/*---------------------------
			Handle collision mesh
			---------------------------*/
			
			// If collision mesh is present
			if(getObjectByName(COLLISION_MESH_NAME) != null)
			{
				// Use dummy box as collision mesh root
				_collisionMesh = new Box(1, 1, 1, 1, 1, 1);
				_collisionMesh.name = "collision-mesh-root-new";
				
				// Needed only for collision mesh hierarchy showing up in the debug tree 
				addChild(_collisionMesh);
				
				// Create an octree (from collision hierachy) for static colliders
				_staticCollisionOctree = new CollisionOctree(Mesh(getObjectByName(COLLISION_MESH_NAME)), 5, 5);
				_staticCollisionOctree.wireframeVisible = false;
				
				// Flatten collision mesh hierachy and add to the root
				var flattenedCollisionMesh:Vector.<Mesh> = Utils.getFlattenedMeshHierachy(Mesh(getObjectByName(COLLISION_MESH_NAME)));
				var global:Vector3D;
				
				// Assign global coords to every collision mesh
				for each(var m:Mesh in flattenedCollisionMesh)
				{
					global = m.localToGlobal(Utils.ZERO_VECTOR);				
					_collisionMesh.addChild(m);
					m.x = global.x;
					m.y = global.y;
					m.z = global.z;
				}
				
				// Add all collision mesh colliders
				for(var i:int; i < _collisionMesh.numChildren; i++)
				{
					_staticCollisionOctree.addCollider(Mesh(_collisionMesh.getChildAt(i)));
				}
				
				// Hide collision mesh
				_collisionMesh.visible = false;
			} else {
				// Use terrain mesh as collision mesh instead
				_collisionMesh = _terrainMesh;
				
				// Create an octree (from collision hierachy) for static colliders
				_staticCollisionOctree = new CollisionOctree(_collisionMesh, 5, 5);
				_staticCollisionOctree.wireframeVisible = false;
				_staticCollisionOctree.addCollider(_collisionMesh);
			}
			
			/*---------------------------
			Handle dynamic octree
			---------------------------*/
			
			// Setup dynamic collision octree
			_dynamicCollisionOctree = new CollisionOctree(null, 10, 10);
			Core.instance.addLoopCallbackPost(updateDynamicCollisionOctree);
			
			/*---------------------------
			Debug
			---------------------------*/
			
			if(Globals.DEBUG_MODE)
			{
				generateWireframes();
			}
			
			dispatchEvent(new Event(GameMap.HIERARCHY_CHANGED));
		}
		
		/**
		 * Gets map object3D by name.
		 * 
		 * @param name Object name.
		 * @return Object3D of specified name.
		 */
		public function getObjectByName(name:String):Object3D
		{
			for each(var o:Object3D in _mapObjects)
			{
				if(o.name == name)
					return o;				
			}
			
			return null;
		}
		
		/**
		 * Adds an entity to the map.
		 * 
		 * @param entity Entity to add.
		 * @param marker Optional marker name for setting position of an entity.
		 * @param dynamic Marks whether entity is static or dynamic.
		 */
		public function addEntity(entity:Entity, markerName:String = ""):void
		{
			trace("[GameMap] > Adding entity: " + entity);
			
			var marker:Object3D;
			var globalCoords:Vector3D;
			
			_entities.push(entity);
			
			if(entity is Unit)
			{
				_units.push(entity);
			}
			
			if(markerName != "")
			{
				marker = this.getObjectByName(markerName);
				
				// todo: remove if
				if(marker != null)
				{
					globalCoords = marker.localToGlobal(zeroVector);
					entity.x = globalCoords.x;
					entity.y = globalCoords.y;
					entity.z = globalCoords.z;
				}
			}
			
			addChild(entity);
			
			// Add entity as collider in the collision octree
			if(entity is DynamicEntity)
			{
				if(!(entity as DynamicEntity).excludeFromCollisions)			
				{
					_dynamicEntities.push(entity);
					_dynamicCollisionOctree.addCollider(entity.collisionMesh);					
				}
				
			} else if(entity is StaticEntity)
			{
				_staticCollisionOctree.addCollider(entity.collisionMesh);
			}
			
			dispatchEvent(new Event(GameMap.HIERARCHY_CHANGED));
		}
		
		/**
		 * Removes entity from map.
		 *
		 * @param entity Entity to remove.
		 */
		public function removeEntity(entity:Entity):void
		{
			var i:int;
			
			// Remove from entities list
			for(i = 0; i < _entities.length; i++)
			{
				if(_entities[i] == entity)
				{
					_entities.splice(i, 1);
				}
			}
			
			// If unit, remove from units list
			if(entity is Unit)
			{
				for(i = 0; i < units.length; i++)
				{
					if(units[i] == entity)
					{
						units.splice(i, 1);
					}
				}
			}
			
			// Remove from collision octree if dynamic and collision enabled entity
			if(entity is DynamicEntity)
			{
				if((!entity as DynamicEntity).excludeFromCollisions)			
				{
					for(i = 0; i < _dynamicEntities.length; i++)
					{
						if(_dynamicEntities[i] == entity)
						{
							_dynamicEntities.splice(i, 1);
							_dynamicCollisionOctree.removeCollider(entity.collisionMesh);
							break;
						}
					}			
				}
				
			} else if(entity is StaticEntity)
			{
				_staticCollisionOctree.removeCollider(entity.collisionMesh);
			}		
			
			dispatchEvent(new Event(GameMap.HIERARCHY_CHANGED));
		}
		
		/**
		 * Returns entity by name.
		 * 
		 * @param name Name of the entity.
		 * @return Entity of given name or null if entity is not found.
		 */
		public function getEntityByName(name:String):Entity
		{
			var e:Entity;
			
			for each(var ent:Entity in _entities)
			{
				if(ent.name == name) e = ent;
			}
			
			return e;
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/**
		 * Updates dynamic collision octree each frame.
		 */
		private function updateDynamicCollisionOctree():void
		{
			for each(var e:Entity in _dynamicEntities)
			{
				_dynamicCollisionOctree.updateByCollider(e.collisionMesh);
			}
		}
		
		/*---------------------------
		Debug helpers
		---------------------------*/		
		
		/**
		 * Generates wireframes for map meshes.
		 */
		private function generateWireframes():void
		{				
			var color:uint;		
			var w:WireFrame;		
			
			_genericWireframes = new Object3D;
			_genericWireframes.visible = false;
			_wireframeRoot.addChild(_genericWireframes);			
			
			// Generate terrain mesh wireframe
			_terrainMeshWireframe = Utils.generateWireframeWithChildren(_terrainMesh, TERRAIN_MESH_COLOR);
			_terrainMeshWireframe.visible = false;
			Renderer3D.instance.uploadResources(_terrainMeshWireframe.getResources(true));
			_wireframeRoot.addChild(_terrainMeshWireframe);
			
			// Generate collision mesh wireframe
			_collisionMeshWireframe = Utils.generateWireframeWithChildren(_collisionMesh, COLLISION_MESH_COLOR);
			_collisionMeshWireframe.visible = false;
			Renderer3D.instance.uploadResources(_collisionMeshWireframe.getResources(true));
			_wireframeRoot.addChild(_collisionMeshWireframe);
			
			// Generate wireframes for other meshes
			// too slow for imported hl maps
			/*for each(var m:Mesh in _mapMeshes)
			{
				if(!Utils.isDescendantOf(_terrainMesh, m) && !Utils.isDescendantOf(_collisionMesh, m))
				{
					w = WireFrame.createEdges(m, GENERIC_MESH_COLOR);
					Renderer3D.instance.uploadResources(w.getResources(true));
					_genericWireframes.addChild(w);
				}
			}*/
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Static variable indicating current map.
		 */
		public static function get currentMap():GameMap
		{
			return _currentMap;
		}
		
		/**
		 * List of map meshes.
		 */
		public function get mapMeshes():Vector.<Mesh>
		{
			return _mapMeshes;
		}
		
		/**
		 * List of all map objects.
		 */
		public function get mapObjects():Vector.<Object3D>
		{
			return _mapObjects;
		}
		
		/**
		 * List of lights.
		 */
		public function get lights():Vector.<Light3D>
		{
			return _lights;
		}
		
		/**
		 * List of root level objects.
		 */
		public function set rootLevelObjects(value:Vector.<Object3D>):void
		{
			_rootLevelObjects = value;
		}
		public function get rootLevelObjects():Vector.<Object3D>
		{
			return _rootLevelObjects;
		}
		
		/**
		 * Terrain mesh.
		 */
		public function get terrainMesh():Mesh
		{
			return _terrainMesh;
		}
		
		/**
		 * Collision mesh.
		 */
		public function get collisionMesh():Mesh
		{
			return _collisionMesh;
		}
		
		/**
		 * Terrain wireframe.
		 */
		public function get terrainMeshWireframe():WireFrame
		{
			return _terrainMeshWireframe;
		}
		
		/**
		 * Collision mesh wireframe.
		 */
		public function get collisionMeshWireframe():WireFrame
		{
			return _collisionMeshWireframe;
		}
		
		/**
		 * Wireframes of generic meshes.
		 */
		public function get genericWireframes():Object3D
		{
			return _genericWireframes;
		}
		
		/**
		 * Returns textual representation o level hierarchy.
		 */
		public function get hierarchyText():String
		{
			return Utils.getColoredHierarchyAsHTMLString(this, DynamicEntity);
		}
		
		/**
		 * All wireframes are children of this root object.
		 */
		public function get wireframeRoot():Object3D
		{
			return _wireframeRoot;
		}
		
		/**
		 * List of units.
		 */
		public function get units():Vector.<Unit>
		{
			return _units;
		}
		
		/**
		 * Octree of static colliders.
		 */
		public function get staticCollisionOctree():CollisionOctree
		{
			return _staticCollisionOctree;
		}
		
		/**
		 * Octree of dynamic colliders.
		 */
		public function get dynamicCollisionOctree():CollisionOctree
		{
			return _dynamicCollisionOctree;
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		/**
		 * Clean up.
		 */
		public function dispose():void
		{
			// Remove lopp callbacks
			Core.instance.removeLoopCallbackPost(updateDynamicCollisionOctree);
			
			// Dispose octrees
			_staticCollisionOctree.dispose();
			_dynamicCollisionOctree.dispose();
			
			// Remove entities
			for each(var e:Entity in _entities)
			{
				removeChild(e);
				e.dispose();
			}
			
			_dynamicEntities = null;
			_units = null;
			
			// Dispose resources
			Renderer3D.instance.removeObject3D(this, true);
			
			_currentMap = null;
		}
	}
}