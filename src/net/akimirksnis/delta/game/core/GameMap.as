package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import net.akimirksnis.delta.game.library.Library;
	import net.akimirksnis.delta.game.utils.Globals;
	
	public class GameMap extends Object3D
	{
		public static const TERRAIN_MESH_NAME:String = "mesh-terrain-root";		
		public static const COLLISION_MESH_NAME:String = "mesh-collision-root";			
		public static const GENERIC_MESH_COLOR:uint = 0x0000CC;
		public static const TERRAIN_MESH_COLOR:uint = 0x00CC00;
		public static const COLLISION_MESH_COLOR:uint = 0xCC0000;
		
		private var _wireframes:Vector.<WireFrame> = new Vector.<WireFrame>();	
		
		private var _collisionMesh:Mesh;
		private var _terrainMesh:Mesh;
		private var library:Library = Library.instance;
		
		/**
		 * Class constructor.
		 */
		public function GameMap(mapRootObjects:Vector.<Object3D>)
		{
			super();
			
			// Add all root level objects
			for each(var o:Object3D in mapRootObjects)
			{
				addChild(o);
			}
			
			_terrainMesh = Mesh(library.getMapObjectByName(TERRAIN_MESH_NAME));
			_collisionMesh = Mesh(library.getMapObjectByName(COLLISION_MESH_NAME));
			
			if(Globals.debugMode)
			{
				generateWireframes();
			}
		}
		
		/*---------------------------
		Debug methods
		---------------------------*/	

		/**
		 * Generates wireframes for map meshes.
		 */
		private function generateWireframes():void
		{			
			var color:uint;		
			var wireframeRoot:Object3D = new Object3D();
			var w:WireFrame;
			
			wireframeRoot.name = "wireframe-root";
			addChild(wireframeRoot);
			
			for each(var m:Mesh in Library.instance.mapMeshes)
			{	
				color = GENERIC_MESH_COLOR
				
				if(m.name == TERRAIN_MESH_NAME)
				{
					color = TERRAIN_MESH_COLOR;
				} else if(m.name == COLLISION_MESH_NAME)
				{
					color = COLLISION_MESH_COLOR;
				}
				
				w = WireFrame.createEdges(m, color);
				w.name = "wireframe-" + m.name;
				w.visible = false;
				Renderer3D.instance.uploadResources(w.getResources(true));
				wireframeRoot.addChild(w);
				_wireframes.push(w);
			}
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Terrain mesh (visual part of map).
		 */
		public function get terrainMesh():Mesh
		{
			return _terrainMesh;
		}
		
		/**
		 * Collision mesh (invisible)
		 */
		public function get collisionMesh():Mesh
		{
			return _collisionMesh;
		}
		
		/**
		 * Map wireframes
		 */
		public function get wireframes():Vector.<WireFrame>
		{
			return _wireframes;
		}
	}
}