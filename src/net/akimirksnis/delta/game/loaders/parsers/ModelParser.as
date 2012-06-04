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
	
	import net.akimirksnis.delta.game.core.Renderer3D;
	import net.akimirksnis.delta.game.loaders.parsers.extended.DeltaParserCollada;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	public class ModelParser extends EventDispatcher
	{		
		// test cubemap
		[Embed(source="C:/Users/Varnius/Desktop/altex/src/environmentmaterialexample/environment/left.jpg")] private static const EmbedLeft:Class;
		[Embed(source="C:/Users/Varnius/Desktop/altex/src/environmentmaterialexample/environment/right.jpg")] private static const EmbedRight:Class;
		[Embed(source="C:/Users/Varnius/Desktop/altex/src/environmentmaterialexample/environment/back.jpg")] private static const EmbedBack:Class;
		[Embed(source="C:/Users/Varnius/Desktop/altex/src/environmentmaterialexample/environment/front.jpg")] private static const EmbedFront:Class;
		[Embed(source="C:/Users/Varnius/Desktop/altex/src/environmentmaterialexample/environment/bottom.jpg")] private static const EmbedBottom:Class;
		[Embed(source="C:/Users/Varnius/Desktop/altex/src/environmentmaterialexample/environment/top.jpg")] private static const EmbedTop:Class;
		
		private static const DEFAULT_LIGHTMAP_CHANNEL:int = 1;
		
		// Default normal map (neutral height)
		private static const DEFAULT_NORMAL:TextureResource = Utils.texResFromColor(0x8382ff);
		
		// Default specular map (no specular at all)
		private static const DEFAULT_SPECULAR:TextureResource = Utils.texResFromColor(0x000000);
		
		// Default reflection map (no reflections at all)
		private static const DEFAULT_ENVREFLECTION:TextureResource = Utils.texResFromColor(0x888888);
		
		// Since diffuse color may vary, save generated material by some color only once
		private static var defaultDiffuse:Dictionary = new Dictionary();
		
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
		 * @param geometryOny Parse geometry only and discard any materials.
		 */
		protected function parseMesh(mesh:Mesh, geometryOnly:Boolean = false):void
		{
			// Handle default maps
			if(!DEFAULT_NORMAL.isUploaded)
				DEFAULT_NORMAL.upload(Globals.stage3D.context3D);		
			
			if(!DEFAULT_SPECULAR.isUploaded)
				DEFAULT_SPECULAR.upload(Globals.stage3D.context3D);
			
			if(!DEFAULT_ENVREFLECTION.isUploaded)
				DEFAULT_ENVREFLECTION.upload(Globals.stage3D.context3D);
			
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
						
						// Possible maps
						var diffuse:TextureResource         = parserMaterial.textures["diffuse"];
						var normal:TextureResource          = parserMaterial.textures["bump"];
						var specular:TextureResource        = parserMaterial.textures["specular"];
						var emission:TextureResource        = parserMaterial.textures["emission"];
						var glossiness:TextureResource      = parserMaterial.textures["glossiness"];						
						var envreflection:TextureResource   = parserMaterial.textures["reflection"];
						var opacity:TextureResource     	= parserMaterial.textures["transparent"];
						
						/*---------------------------
						Handle each map
						---------------------------*/
						
						if(diffuse == null)
						{
							// Generate default diffuse material only once per color and save it in the dictionary
							if(!defaultDiffuse[parserMaterial.colors.diffuse])
							{								
								defaultDiffuse[parserMaterial.colors.diffuse] = Utils.texResFromColor(parserMaterial.colors.diffuse);
								(defaultDiffuse[parserMaterial.colors.diffuse] as TextureResource).upload(Globals.stage3D.context3D);
							}
							
							diffuse = defaultDiffuse[parserMaterial.colors.diffuse] as TextureResource;
							
							trace("[ModelParser] > No diffuse map for:", mesh.name);
						}					
						 
						if(normal == null)
						{
							// Make normal from default (zero height) color
							normal = DEFAULT_NORMAL;
						}						
						 
						if(specular == null)
						{							
							specular = DEFAULT_SPECULAR;						
						}
						
						if(emission == null)
						{							
							//
						}						
						
						if(glossiness == null)
						{
							//
						}
						  
						if(envreflection == null)
						{
							envreflection = DEFAULT_ENVREFLECTION;
						}						
						  
						if(opacity == null)
						{
							//
						}	
						
						/*---------------------------
						Determine material type
						---------------------------*/
						
						if(emission != null)
						{
							material = new EnvironmentMaterial(diffuse, null, normal, envreflection, emission, opacity);
							(material as EnvironmentMaterial).lightMapChannel = 1;
							(material as EnvironmentMaterial).environmentMap = new BitmapCubeTextureResource(new EmbedLeft().bitmapData, new EmbedRight().bitmapData, new EmbedBack().bitmapData, new EmbedFront().bitmapData, new EmbedBottom().bitmapData, new EmbedTop().bitmapData);   
							Renderer3D.instance.uploadResource((material as EnvironmentMaterial).environmentMap);
							
						} else {
							
							// Standart material with diffuse/bump/specular/glossiness/opacity maps and per-pixel lighting computation
							material = new StandardMaterial(diffuse, normal, specular, glossiness, opacity);
							
							// Use tangent space for normals
							(material as StandardMaterial).normalMapSpace = NormalMapSpace.TANGENT_RIGHT_HANDED;
						}
						
						/*---------------------------
						Push external textures to 
						the load queue
						---------------------------*/
						
						if(diffuse is ExternalTextureResource) 
							textures.push(diffuse);
						
						if(normal is ExternalTextureResource)     
							textures.push(normal);
						
						if(specular is ExternalTextureResource)   
							textures.push(specular);
						
						if(emission is ExternalTextureResource)        
							textures.push(emission); 
						
						if(glossiness is ExternalTextureResource)        
							textures.push(glossiness); 
						
						if(envreflection is ExternalTextureResource)        
							textures.push(envreflection); 
						
						if(opacity is ExternalTextureResource)
							textures.push(opacity);
						
						// Apply material to mesh 
						surface.material = material;
					} else {
						trace("[ModelParser] > No materials found for: " + mesh.name);
					}  
				}
				
				addToLoadingQueue(textures);
			}
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