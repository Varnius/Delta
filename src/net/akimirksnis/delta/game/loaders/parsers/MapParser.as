package net.akimirksnis.delta.game.loaders.parsers
{
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.loaders.*;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.objects.*;
	import alternativa.engine3d.resources.*;
	
	import flash.utils.ByteArray;
	
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.loaders.parsers.extended.DeltaParserA3D;
	
	public class MapParser extends ModelParser
	{		
		public function MapParser()
		{
			super();
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Parses Collada map.
		 * 
		 * @param map Map object to fill.
		 * @param mapData Map XML data
		 * @param materialPath Map materials path.
		 */
		public function parseColladaMap(
			map:GameMap,
			mapData:XML,
			materialsPath:String
		):void
		{
			var currentMesh:Mesh;
			var parser:ParserCollada = new ParserCollada();
			var meshVectorTemp:Vector.<Mesh> = new Vector.<Mesh>();
			
			// Parse file and trim filepaths to textures
			parser.parse(mapData, materialsPath, true);	
			// Set list of root objectsfor the map
			map.rootLevelObjects = parser.hierarchy.concat();
			
			// Trace some info
			trace("[ModelParser] > Objects in map file: " + parser.objects);
			trace("[ModelParser] > Materials in map file: " + parser.materials);
			trace("[ModelParser] > Lights in map file: " + parser.lights);
			
			// Push objects to vectors
			for each(var o:* in parser.objects)
			{				
				if((o is Object3D))  
				{
					map.mapObjects.push(o);
				}
				
				// Ambient lights				
				if(o is AmbientLight)  
				{
					map.lights.push(o);				
				}
				
				// Directional lights
				if(o is DirectionalLight)  
				{
					map.lights.push(o);	
				}
				
				// Omnilights
				if(o is OmniLight)  
				{
					map.lights.push(o);	
				}							 
				
				// Spotlights
				if(o is SpotLight)  
				{					
					map.lights.push(o);	
				}
				
				// Meshes				
				if(o is Mesh)  
				{
					meshVectorTemp.push(o);
					map.mapMeshes.push(o);
				}
			}
			
			// Parse meshes - upload geometry and initiate mesh texture loading  
			for each(var mesh:Mesh in meshVectorTemp)
			{				
				// Parse mesh (parse geometry ony if current mesh is collision mesh
				parseMesh(mesh, mesh.name == GameMap.COLLISION_MESH_NAME);
			}
			
			// Clean parser outer references
			parser.clean();
		}
		
		/**
		 * Parses binary A3D map.
		 * 
		 * @param map Map object to fill.
		 * @param mapData Map binary data.
		 * @param materialPath Map materials path.
		 */
		public function parseA3DMap(			
			map:GameMap,
			mapData:ByteArray,
			materialsPath:String
		):void
		{
			var currentMesh:Mesh;
			var parser:DeltaParserA3D = new DeltaParserA3D();
			var meshVectorTemp:Vector.<Mesh> = new Vector.<Mesh>();
			
			// Parse file and trim filepaths to textures	
			// Use extended class that has an ability to append material path to the texture name
			parser.parse2(mapData, materialsPath);
				
			// Set list of root objectsfor the map
			map.rootLevelObjects = parser.hierarchy.concat();
			
			// Trace some info
			trace("[MapParser] > Objects in .A3D map file: " + parser.objects);
			trace("[MapParser] > Materials in .A3D map file: " + parser.materials);
			
			// Push objects to vectors
			for each(var o:* in parser.objects)
			{				
				if((o is Object3D))  
				{
					map.mapObjects.push(o);
				}
				
				// Ambient lights				
				if(o is AmbientLight)  
				{
					map.lights.push(o);				
				}
				
				// Directional lights
				if(o is DirectionalLight)  
				{
					map.lights.push(o);	
				}
				
				// Omnilights
				if(o is OmniLight)  
				{
					map.lights.push(o);	
				}							 
				
				// Spotlights
				if(o is SpotLight)  
				{					
					map.lights.push(o);	
				}
				
				// Meshes				
				if(o is Mesh)  
				{
					meshVectorTemp.push(o);
					map.mapMeshes.push(o);
				}
			}
			
			// Parse meshes - upload geometry and initiate mesh texture loading  
			for each(var mesh:Mesh in meshVectorTemp)
			{			
				// Parse mesh (parse geometry ony if current mesh is collision mesh)
				parseMesh(mesh, mesh.name == GameMap.COLLISION_MESH_NAME);
			}
			
			// Clean parser outer references
			parser.clean();
		}
	}
}