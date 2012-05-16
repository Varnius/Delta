package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import net.akimirksnis.delta.game.collisions.CollisionOctreeWrapper;
	import net.akimirksnis.delta.game.entities.Entity;
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
		
		private var zeroVector:Vector3D = new Vector3D();
		
		// Used for terrain and other stationary objects (entities)
		private var _staticCollisionOctree:CollisionOctreeWrapper;
		
		// Used for moving entities
		private var _dynamicCollisionOctree:CollisionOctreeWrapper;	
		private var _dynamicEntities:Vector.<Entity> = new Vector.<Entity>();
		
		
		private var _mapMeshes:Vector.<Mesh> = new Vector.<Mesh>();		
		private var _mapObjects:Vector.<Object3D> = new Vector.<Object3D>();
		private var _rootLevelObjects:Vector.<Object3D>;
		private var _lights:Vector.<Light3D> = new Vector.<Light3D>();
		private var _entities:Vector.<Entity> = new Vector.<Entity>();
		private var _collisionMesh:Mesh;
		private var _terrainMesh:Mesh;
		private var _mapProperties:Dictionary = new Dictionary();
		private var _wireframeRoot:Object3D;
		
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
			
			// Add all root level objects
			for each(var o:Object3D in _rootLevelObjects)
			{
				addChild(o);
			}
			
			_terrainMesh = Mesh(getObjectByName(TERRAIN_MESH_NAME));
			_collisionMesh = Mesh(getObjectByName(COLLISION_MESH_NAME));
			
			// Hide collision mesh
			// todo: still shows up somehow
			_collisionMesh.visible = false;
			
			// Use terrain mesh for collisions if collision mesh is unavailable
			if(_collisionMesh == null)
			{
				_collisionMesh = _terrainMesh;
			}	
			
			if(Globals.DEBUG_MODE)
			{
				generateWireframes();
			}
			
			// Create an octree (from collision mesh) for static colliders
			_staticCollisionOctree = new CollisionOctreeWrapper(_collisionMesh);
			_staticCollisionOctree.wireframeVisible = false;
			
			// Add all collision mesh colliders
			for each(var m:Mesh in Utils.getMeshHierachyAsVector(_collisionMesh))
			{
				_staticCollisionOctree.addCollider(m);
			}		
			
			// Setup dynamic collision octree
			_dynamicCollisionOctree = new CollisionOctreeWrapper();
			Core.instance.addLoopCallbackPost(updateDynamicCollisionOctree);
						
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
		public function addEntity(entity:Entity, markerName:String = "", dynamic:Boolean = false):void
		{
			trace("[GameMap] > Adding entity: " + entity);
			
			var marker:Object3D;
			var globalCoords:Vector3D;
			
			entities.push(entity);
			
			if(markerName != "")
			{
				marker = this.getObjectByName(markerName);
				
				// todo: remove if
				if(marker != null)
				{
					globalCoords = marker.localToGlobal(zeroVector);
					entity.m.x = globalCoords.x;
					entity.m.y = globalCoords.y;
					entity.m.z = globalCoords.z;	
				}
			}
			
			addChild(entity.m);
			
			// Add entity as collider in the collision octree
			if(!entity.excludeFromCollisions)
			{
				if(dynamic)				
				{
					_dynamicCollisionOctree.addCollider(entity.collisionMesh);
					_dynamicEntities.push(entity);
				} else {
					_staticCollisionOctree.addCollider(entity.collisionMesh);
				}
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
			var index:int = -1;
			
			for each(var e:Entity in entities)
			{
				if(e == entity)
				{
					index = entities.indexOf(e);
				}
			}
			
			if(index != -1)
			{
				entities.splice(index, 1);
			} else {
				trace("[GameCore] Entity to remove not found.");
			}
			
			entity.dispose();
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
			
			for each(var ent:Entity in entities)
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
			
			_wireframeRoot = new Object3D();
			
			// Create root element as parent element for wireframes
			_wireframeRoot.name = "wireframe-root";
			addChild(_wireframeRoot);
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
			for each(var m:Mesh in _mapMeshes)
			{
				if(!Utils.isDescendantOf(_terrainMesh, m) && !Utils.isDescendantOf(_collisionMesh, m))
				{
					w = WireFrame.createEdges(m, GENERIC_MESH_COLOR);
					Renderer3D.instance.uploadResources(w.getResources(true));
					_genericWireframes.addChild(w);
				}
			}
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
		 * List of entities.
		 */
		public function get entities():Vector.<Entity>
		{
			return _entities;
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
		 * Map object property dictionary.
		 */
		public function get mapProperties():Dictionary
		{
			return _mapProperties;
		}
		public function set mapProperties(value:Dictionary):void
		{
			_mapProperties = value;
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
			return Utils.getColoredHierarchyAsHTMLString(this);
		}

		/**
		 * All wireframes are children of this root object.
		 */
		public function get wireframeRoot():Object3D
		{
			return _wireframeRoot;
		}
		
		/**
		 * Octree of static colliders.
		 */
		public function get staticCollisionOctree():CollisionOctreeWrapper
		{
			return _staticCollisionOctree;
		}
		
		/**
		 * Octree of dynamic colliders.
		 */
		public function get dynamicCollisionOctree():CollisionOctreeWrapper
		{
			return _dynamicCollisionOctree;
		}
	}
}