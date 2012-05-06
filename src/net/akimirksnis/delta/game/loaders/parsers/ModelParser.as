package net.akimirksnis.delta.game.loaders.parsers
{
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.loaders.*;
	import alternativa.engine3d.materials.*;
	import alternativa.engine3d.objects.*;
	import alternativa.engine3d.resources.*;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	public class ModelParser extends EventDispatcher
	{		
		private var resourceLoader:ResourceLoader = new ResourceLoader();
		private var materialsLoaded:int = 0;
		private var materialsTotal:int = 0;
		
		/*---------------------------
		Loading materials
		---------------------------*/		
		
		/**
		 * Starts loading materials.
		 */
		public function loadMaterials():void
		{
			resourceLoader.addEventListener(ProgressEvent.PROGRESS, onMaterialLoadingProgress);
			resourceLoader.addEventListener(Event.COMPLETE, onMaterialLoadingComplete);
			resourceLoader.load(Globals.stage3D.context3D);
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Parses Collada model.
		 * 
		 * @param modelXML Model file as XML.
		 * @param materialsPath Materials directory path.
		 * @param animationDictionary Dictionary for storing Object3D - AnimationClip pairs.
		 * @param propertyDictionary Dictionary for storing properties of parsed objects.
		 * 
		 * @return Vector containing parsed objects.
		 */
		public function parseColladaModel(
			modelXML:XML,
			materialsPath:String,
			animationDictionary:Dictionary,
			propertyDictionary:Dictionary
		):Vector.<Object3D>
		{
			var parser:DeltaParserCollada = new DeltaParserCollada();
			var meshVectorTemp:Vector.<Mesh> = new Vector.<Mesh>();
			var skinVectorTemp:Vector.<Skin> = new Vector.<Skin>();
			var parserProperties:Dictionary;
			var result:Vector.<Object3D> = new Vector.<Object3D>();
			
			// Parse model (trim texture filepaths)
			parser.parse(modelXML, materialsPath, true);
			
			trace("[ModelParser] > Objects in model file \"" + materialsPath + "\": " + parser.objects);
			trace("[ModelParser] > Materials in model file \"" + materialsPath + "\": " + parser.materials);

			// Push to respective vectors
			for each(var o:* in parser.objects)
			{			
				if(o is Mesh)  
				{
					meshVectorTemp.push(o);					
				}
				
				if(o is Skin)  
				{
					skinVectorTemp.push(o);
				}
				
				if(o is Mesh || o is Skin)
				{
					result.push(o);
				}
			}
			
			// Parse meshes - upload geometry and initiate mesh texture loading  
			for each(var mesh:Mesh in meshVectorTemp)
			{
				var properties:Object = parser.getPropertiesByObject(mesh);
				var lightPerVertex:Boolean = false;
				
				if(!(mesh is Skin) && properties != null && properties["lightingPrecision"] == "vertex")
				{
					lightPerVertex = true;
				}
				
				parseMesh(mesh, lightPerVertex);
			}
			
			// Get animations for skins
			for each(var skin:Skin in skinVectorTemp)
			{
				animationDictionary[skin] = parser.getAnimationByObject(skin);
			}
			
			// Copy user defined properties
			parserProperties = parser.properties;
			for (var key:Object in parserProperties)
			{
				propertyDictionary[key] = parserProperties[key];
			}
			
			parser.clean();
			
			return result;
		}
		
		/**
		 * Parses binary (3DS/A3D) model.
		 * 
		 * @param model Model data as ByteArray.
		 * @param materialsPath Materials directory path.
		 * 
		 * @return Vector containing parsed objects.
		 */
		public function parseBinaryModel(			
			model:ByteArray,
			format:String,
			materialsPath:String,
			animationDictionary:Dictionary
			//propertyDictionary:Dictionary*/
		):Vector.<Object3D>
		{
			var parser:Parser;
			var meshVectorTemp:Vector.<Mesh> = new Vector.<Mesh>();
			var skinVectorTemp:Vector.<Skin> = new Vector.<Skin>();
			var parserProperties:Dictionary;
			var result:Vector.<Object3D> = new Vector.<Object3D>();
			
			switch(format)
			{
				case BinaryModelFormat.A3D:
				{
					parser = new ParserA3D();
					ParserA3D(parser).parse(model);
					break;
				}
				case BinaryModelFormat.THREE_DS:
				{
					parser = new Parser3DS();
					Parser3DS(parser).parse(model);
					break;
				}
				default:
				{
					throw new Error("[ModelParser] > Unsupported file format: '" + format + "'");
				}
			}
			
			trace("[ModelParser] > Objects in model file \"" + materialsPath + "\": " + parser.objects);
			trace("[ModelParser] > Materials in model file \"" + materialsPath + "\": " + parser.materials);
			
			// Push to respective vectors
			for each(var o:* in parser.objects)
			{			
				if(o is Mesh)  
				{
					meshVectorTemp.push(o);
				}
				
				if(o is Skin)  
				{
					skinVectorTemp.push(o);
				}
				
				if(o is Mesh || o is Skin)
				{
					result.push(o);
				}
			}
			
			// Parse meshes - upload geometry and initiate mesh texture loading  
			for each(var mesh:Mesh in meshVectorTemp)
			{				
				parseMesh(mesh);
			}
			
			// todo:parse animations by object, not working now
			for each(var ani:AnimationClip in parser.animations)
			{				
				/*for(var i:int = 0; i < ani.numTracks; i++)
				{
					trace("track for obj: ",ani.getTrackAt(i).object);
				}*/
			
				for each(var obj:Object3D in ani.objects)
				{					
					if(obj is Skin)
					{						
						animationDictionary[obj] = ani;						
						break;	
					}
				}
			}
			
			// todo:somehow parse user properties			
			parser.clean();
			
			return result;
		}
		
		/**
		 * Parses sprite.
		 */
		public function parseSprite(
			name:String,
			width:int,
			height:int,
			diffuseMapPath:String,
			opacityMapPath:String,			
			opacity:Number
		):Sprite3D
		{
			var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>();						
			var diffuse:ExternalTextureResource = new ExternalTextureResource(diffuseMapPath);
			var opacityMap:ExternalTextureResource = opacityMapPath != "none" ? new ExternalTextureResource(opacityMapPath) : null;			
			var sprite:Sprite3D = new Sprite3D(width, height, new TextureMaterial(diffuse, opacityMap, opacity));				
			sprite.name = name;
			
			textures.push(diffuse);
			
			if(opacityMap is ExternalTextureResource)
			{
				textures.push(opacityMap);
			}
							
			// Load materials to VGA
			addToLoadingQueue(textures);
			
			return sprite;
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/**
		 * Handles geometry and materials of a mesh.
		 * 
		 * @param mesh Mesh to parse.
		 * @param useVertexLightMaterial Indicates the type of material to apply to the mesh - Standart or VertexLight.
		 */
		protected function parseMesh(mesh:Mesh, useVertexLightMaterial:Boolean = false, geometryOnly:Boolean = false):void
		{			
			// Upload mesh geometry to context3D
			uploadResources(mesh.getResources(false, Geometry));      
			
			// Parse textures of each surface of the mesh 
			var textures:Vector.<ExternalTextureResource> = new Vector.<ExternalTextureResource>(); 
			
			if(!geometryOnly)
			{
				for(var i:uint = 0; i < mesh.numSurfaces; i++)
				{
					var surface:Surface = mesh.getSurface(i);  
					var parserMaterial:ParserMaterial = surface.material as ParserMaterial;
					
					// If one or more materials exist
					if(parserMaterial != null)
					{	
						var material:TextureMaterial;
						
						var diffuse:TextureResource = parserMaterial.textures["diffuse"];  
						if(parserMaterial.textures["diffuse"] == null)
						{
							diffuse = Utils.texResFromColor(parserMaterial.colors.diffuse);
							diffuse.upload(Globals.stage3D.context3D);
							trace("[ModelParser] > No diffuse map for:", mesh.name);
						}	
						
						var opacity:TextureResource  = parserMaterial.textures["opacity"];  
						if(parserMaterial.textures["opacity"] == null)
						{
							opacity = null;
							//trace("[ModelParser] No opacity map for: " + mesh.name);
						}
						
						// Only diffuse and opacity for VertexLight materials
						if(!useVertexLightMaterial)
						{
							var normal:TextureResource = parserMaterial.textures["bump"];  
							if(parserMaterial.textures["bump"] == null)
							{
								// Make normal from default (zero height) color
								normal = Utils.texResFromColor(0x8382ff);
								normal.upload(Globals.stage3D.context3D);
							}
							
							var specular:TextureResource = parserMaterial.textures["specular"];  
							if(parserMaterial.textures["specular"] == null)
							{							
								specular = Utils.texResFromColor(parserMaterial.colors.specular);
								specular.upload(Globals.stage3D.context3D);
							}
							
							var glossiness:TextureResource = parserMaterial.textures["glossiness"];  
							if(parserMaterial.textures["glossiness"] == null)
							{
								glossiness = null;
							}
							
							// Standart material with diffuse/bump/specular/glossiness/opacity maps and per-pixel lighting computation
							material = new StandardMaterial(diffuse, normal, specular, glossiness, opacity);
							// Use tangent space for normals
							(material as StandardMaterial).normalMapSpace = NormalMapSpace.TANGENT_RIGHT_HANDED;
						} else {
							// Efficient VertexLight material with diffuse/opacity maps only and per-vertex lighting computation
							material = new VertexLightTextureMaterial(diffuse, opacity, parserMaterial.transparency);
						}
						
						// Push to load queue if textures are external files					
						if(parserMaterial.textures["diffuse"] is ExternalTextureResource)  
							textures.push(parserMaterial.textures["diffuse"]);  
						
						if(parserMaterial.textures["opacity"] is ExternalTextureResource)                      
							textures.push(parserMaterial.textures["opacity"]);
						
						if(!useVertexLightMaterial)
						{					
							if(parserMaterial.textures["bump"] is ExternalTextureResource)                          
								textures.push(parserMaterial.textures["bump"]);                         
							
							if(parserMaterial.textures["specular"] is ExternalTextureResource)                      
								textures.push(parserMaterial.textures["specular"]);  
							
							if(parserMaterial.textures["glossiness"] is ExternalTextureResource)                          
								textures.push(parserMaterial.textures["glossiness"]);                         
						}					
						
						// Apply material to mesh 
						surface.material = material;						
					} else {  
						//throw new Error("No materials found for: " + mesh.name);
						trace("[ModelParser] > No materials found for: " + mesh.name);
					}  
				}
			}
				
			// Load materials to VGA
			addToLoadingQueue(textures);
		}
		
		/**
		 * Adds in-file textures to loading queue.
		 * 
		 * @param textures Resource ExternalTextureResource vector.
		 */
		protected function addToLoadingQueue(textures:Vector.<ExternalTextureResource>):void
		{
			resourceLoader.addResources(textures);
			materialsTotal += textures.length;
		}
		
		/**
		 * Uploads resources to VGA.
		 * 
		 * @param resources Resources to upload.
		 */
		private function uploadResources(resources:Vector.<Resource>):void
		{
			for each(var resource:Resource in resources)
			{
				resource.upload(Globals.stage3D.context3D);
			}
		}
		
		/*---------------------------
		Event callbacks
		---------------------------*/
		
		/**
		 * Called when material loading is in progress.
		 * 
		 * @param e Event object.
		 */
		private function onMaterialLoadingProgress(e:ProgressEvent):void
		{
			materialsLoaded++;
			e.bytesLoaded = materialsLoaded;
			e.bytesTotal = materialsTotal;
			dispatchEvent(e);
		}		
		
		/**
		 * Called when material loading is complete.
		 * 
		 * @param e Event object.
		 */
		private function onMaterialLoadingComplete(e:Event):void
		{		
			dispatchEvent(e);
			materialsLoaded = materialsTotal = 0;
			resourceLoader.removeEventListener(ProgressEvent.PROGRESS, onMaterialLoadingProgress);
			resourceLoader.removeEventListener(Event.COMPLETE, onMaterialLoadingComplete);						
		}
	}
}