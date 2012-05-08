package net.akimirksnis.delta.game.loaders.parsers
{
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.loaders.*;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.objects.*;
	import alternativa.engine3d.resources.*;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.game.core.GameMap;
	
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
		 * @param modelXML Map file as XML.
		 * @param materialsPath Materials directory path.
		 * @param propertyDictionary Dictionary for storing properties of parsed objects.
		 */
		public function parseColladaMap(
			map:GameMap,
			mapXML:XML,
			materialsPath:String
		):void
		{
			var currentMesh:Mesh;
			var parser:DeltaParserCollada = new DeltaParserCollada();
			var meshVectorTemp:Vector.<Mesh> = new Vector.<Mesh>();
			
			// Parse file and trim filepaths to textures
			parser.parse(mapXML, materialsPath, true);	
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
			
			// Store map object props in the library
			map.mapProperties = parser.properties;
			
			var lightPerVertex:Boolean;
			var properties:Object;
			var geometryOnly:Boolean;
			
			// Parse meshes - upload geometry and initiate mesh texture loading  
			for each(var mesh:Mesh in meshVectorTemp)
			{
				properties = parser.getPropertiesByObject(mesh);				
				geometryOnly = false;
				
				// Light mesh per vertex?
				lightPerVertex = properties != null && properties["lightingPrecision"] == "vertex";
				
				// Skip collision mesh (???)
				if(mesh.name == GameMap.COLLISION_MESH_NAME)
				{
					//geometryOnly = true;
					//mesh.visible = false;
					continue;
				}
				
				// Parse mesh
				parseMesh(mesh, lightPerVertex, geometryOnly);
			}
			
			// Clean parser outer references
			parser.clean();
		}
		
		/**
		 * Parses binary (A3D) map.
		 * 
		 * @param model Map data as ByteArray.
		 * @param format Map format (currently only A3D).
		 * @param materialsPath Materials directory path.
		 * 
		 * @return Vector containing parsed objects.
		 */
		public function parseBinaryMap(			
			map:ByteArray,
			format:String,
			materialsPath:String,
			animationDictionary:Dictionary
			//propertyDictionary:Dictionary*/
		):void
		{
			
		}
	}
}