package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	public class GameMap extends Object3D
	{
		public static const TERRAIN_MESH_NAME:String = "mesh-terrain-root";		
		public static const COLLISION_MESH_NAME:String = "mesh-collision-root";
		public static const GENERIC_MESH_COLOR:uint = 0x0000CC;
		public static const TERRAIN_MESH_COLOR:uint = 0x00CC00;
		public static const COLLISION_MESH_COLOR:uint = 0xCC0000;
		
		private static var _currentMap:GameMap;
		
		private var _mapMeshes:Vector.<Mesh> = new Vector.<Mesh>();		
		private var _mapObjects:Vector.<Object3D> = new Vector.<Object3D>();
		private var _rootLevelObjects:Vector.<Object3D>;
		private var _lights:Vector.<Light3D> = new Vector.<Light3D>();	
		
		// Properties of map objects
		private var _mapProperties:Dictionary = new Dictionary();
		
		private var _collisionMesh:Mesh;
		private var _terrainMesh:Mesh;
		
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
			
			_terrainMesh = Mesh(getMapObjectByName(TERRAIN_MESH_NAME));
			_collisionMesh = Mesh(getMapObjectByName(COLLISION_MESH_NAME));
			
			if(Globals.debugMode)
			{
				generateWireframes();
			}
		}
		
		/**
		 * Gets map object3D by name.
		 * 
		 * @param name Object name.
		 * @return Object3D of specified name.
		 */
		public function getMapObjectByName(name:String):Object3D
		{
			for each(var o:Object3D in _mapObjects)
			{
				if(o.name == name)
					return o;				
			}
			
			return null;
		}
		
		/*---------------------------
		Debug methods
		---------------------------*/		

		/**
		 * Generates wireframes for map meshes.
		 */
		private function generateWireframes():void
		{			
			var wireframeRoot:Object3D = new Object3D();
			var color:uint;		
			var w:WireFrame;
			
			// Create root element as parent element for wireframes
			wireframeRoot.name = "wireframe-root";
			addChild(wireframeRoot);
			_genericWireframes = new Object3D;
			_genericWireframes.visible = false;
			wireframeRoot.addChild(_genericWireframes);			
			
			// Generate terrain mesh wireframe
			_terrainMeshWireframe = Utils.generateWireframeWithChildren(_terrainMesh, TERRAIN_MESH_COLOR);
			_terrainMeshWireframe.visible = false;
			Renderer3D.instance.uploadResources(_terrainMeshWireframe.getResources(true));
			wireframeRoot.addChild(_terrainMeshWireframe);
			
			// Generate collision mesh wireframe
			_collisionMeshWireframe = Utils.generateWireframeWithChildren(_collisionMesh, COLLISION_MESH_COLOR);
			_collisionMeshWireframe.visible = false;
			Renderer3D.instance.uploadResources(_collisionMeshWireframe.getResources(true));
			wireframeRoot.addChild(_collisionMeshWireframe);		
			
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
	}
}