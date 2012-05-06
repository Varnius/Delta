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
	import net.akimirksnis.delta.game.library.Library;
	
	public class MapParser extends ModelParser
	{
		private var library:Library = Library.instance;
		
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
			mapXML:XML,
			materialsPath:String
		):Vector.<Object3D>
		{
			var currentMesh:Mesh;
			var parser:DeltaParserCollada = new DeltaParserCollada();
			var meshVectorTemp:Vector.<Mesh> = new Vector.<Mesh>();
			var result:Vector.<Object3D>;
			
			// Parse file and trim filepaths to textures
			parser.parse(mapXML, materialsPath, true);	
			// Return list of root objects
			result = parser.hierarchy.concat();
			
			// Trace some info
			trace("[ModelParser] > Objects in map file: " + parser.objects);
			trace("[ModelParser] > Materials in map file: " + parser.materials);
			trace("[ModelParser] > Lights in map file: " + parser.lights);
			
			// Push objects to vectors
			for each(var o:* in parser.objects)
			{				
				if((o is Object3D))  
				{
					library.mapObjects.push(o);
				}
				
				// Ambient lights				
				if(o is AmbientLight)  
				{
					library.lights.push(o);				
				}
				
				// Directional lights
				if(o is DirectionalLight)  
				{
					library.lights.push(o);
				}
				
				// Omnilights
				if(o is OmniLight)  
				{
					library.lights.push(o);  
				}							 
				
				// Spotlights
				if(o is SpotLight)  
				{					
					library.lights.push(o);
				}
				
				// Meshes				
				if(o is Mesh)  
				{
					meshVectorTemp.push(o);
					library.meshes.push(o);
					library.mapMeshes.push(o);
				}
			}
			
			// Store map object props in the library
			library.mapProperties = parser.properties;
			
			// Parse meshes - upload geometry and initiate mesh texture loading  
			for each(var mesh:Mesh in meshVectorTemp)
			{
				var properties:Object = parser.getPropertiesByObject(mesh);				
				var lightPerVertex:Boolean;
				
				// Light mesh per vertex?
				lightPerVertex = properties != null && properties["lightingPrecision"] == "vertex";
				
				// Skip collision mesh (???)
				if(mesh.name == GameMap.COLLISION_MESH_NAME)
				{
					continue;
				}
				
				// Parse mesh
				parseMesh(mesh, lightPerVertex);
			}
			
			// Clean parser outer references
			parser.clean();
			
			return result;
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