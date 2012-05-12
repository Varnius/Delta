package net.akimirksnis.delta.game.loaders
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Sprite3D;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.ProgressEvent;
	import flash.utils.ByteArray;
	
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.gui.controllers.PreloaderOverlayController;
	import net.akimirksnis.delta.game.core.Library;
	import net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent;
	import net.akimirksnis.delta.game.loaders.loaders.MapLoader;
	import net.akimirksnis.delta.game.loaders.loaders.ModelLoader;
	import net.akimirksnis.delta.game.loaders.loaders.XMLConfigLoader;
	import net.akimirksnis.delta.game.loaders.parsers.MapParser;
	import net.akimirksnis.delta.game.loaders.parsers.ModelParser;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;

	[Event(name="configsLoaded", type="net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent")]
	[Event(name="assetsLoaded", type="net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent")]
	[Event(name="mapLoaded", type="net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent")]
	public class CoreLoader extends EventDispatcher
	{
		private var XMLPaths:Array;
		private var library:Library;
		private var rawModels:Vector.<Object>;
		private var _configs:Vector.<XML>;		
		
		// Config load progress
		private var configsLoaded:Boolean = false;
		
		// Asset load progress
		private var assetLoadStatus:Object =
		{
			models: 	false,
			sprites: 	false,
			materials: 	false,				
			animations: true,
			sounds: 	true			
		};
		
		// Map load progress
		private var mapLoadStatus:Object =
		{
			geometry: 	false,
			materials:  false
		};
		
		// Preloader
		private var preloader:PreloaderOverlayController;
		private var totalSteps:Number;
		private var currentStep:Number;
		
		/**
		 * Class constructor.
		 * 
		 * @param XMLPaths An array containing paths to XML files to load.
		 * @param library Reference to the library object.
		 */
		public function CoreLoader(XMLPaths:Array, preloader:PreloaderOverlayController)
		{
			this.XMLPaths = XMLPaths;
			this.library = Library.instance;
			this.preloader = preloader;			
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Load assets specified in the asset XML files.
		 */
		public function loadAssets():void
		{		
			currentStep = totalSteps = 0;
			
			// Calculate number of loading steps
			for(var property:String in assetLoadStatus)
			{
				totalSteps++;
			}
			
			// +1 for config laoding
			totalSteps++;
			
			// Load XML configs
			var xmlLoader:XMLConfigLoader = new XMLConfigLoader();
			xmlLoader.addEventListener(Event.COMPLETE, onConfigsLoaded, false, 0, true);			
			xmlLoader.load(XMLPaths);
			
			// Update preloader
			preloader.focus();
			preloader.text = "Loading configuration...";
		}
		
		/**
		 * Loads map.
		 * 
		 * @param Filename of a map to load.
		 */
		public function loadMap(filename:String):void
		{
			currentStep = totalSteps = 0;
			
			// Calculate number of loading steps
			for(var property:String in mapLoadStatus)
			{
				totalSteps++;
			}
			
			// Update preloader
			preloader.focus();
			preloader.text = "Loading map...";
			
			// Load map
			var mapLoader:MapLoader = new MapLoader(Globals.LOCAL_ROOT + Globals.MAP_DIR, filename);
			mapLoader.addEventListener(Event.COMPLETE, onMapLoaded, false, 0, true);
			mapLoader.loadMap();
		}
		
		/**
		 * Gets config XML by filename.
		 * 
		 * @param filename Name of the config file.
		 */
		public function getConfigByFilename(filename:String):XML
		{
			var result:XML;
			
			// todo order
			for each(var fn:String in XMLPaths)
			{
				if(fn == filename)
				{
					return _configs[XMLPaths.indexOf(fn)];
				}
			}
			
			return result;
		}
		
		/*---------------------------
		Asset loading event callbacks
		---------------------------*/
		
		/**
		 * Fired after configs are loaded.
		 * 
		 * @param e Event object.
		 */
		private function onConfigsLoaded(e:Event):void
		{
			configsLoaded = true;
			onAssetLoadPartComplete();
			preloader.text = "Loading assets...";			
			
			var loader:XMLConfigLoader = XMLConfigLoader(e.currentTarget);
			loader.removeEventListener(Event.COMPLETE, onConfigsLoaded);
			_configs = loader.loadedData;
			
			// Fill level data
			for each(var x:XML in _configs[0].maps.map)
			{
				library.mapData.push(
					{
						name: Utils.trimExtension(x.@filename).toLowerCase(),
						filename: String(x.@filename),
						skybox: String(x.@skybox)
					}	
				);
			}

			// Load models
			var modelLoader:ModelLoader = new ModelLoader(Globals.LOCAL_ROOT + Globals.MODEL_DIR, _configs[0].models.model);
			modelLoader.addEventListener(Event.COMPLETE, onModelsLoaded, false, 0, true);
			modelLoader.loadModels();
			
			// Load sounds
			// ...
		}
		
		/**
		 * Fired after models are loaded.
		 * 
		 * @param e Event object.
		 */
		private function onModelsLoaded(e:Event):void
		{			
			var loader:ModelLoader = ModelLoader(e.currentTarget);
			var modelParser:ModelParser = new ModelParser();
			var currentModels:Vector.<Object3D>;
			var currentSprite:Sprite3D;
			
			loader.removeEventListener(Event.COMPLETE, onModelsLoaded);
			rawModels = loader.loadedData;
			
			try {
				trace("[CoreLoader] > Parsing model files..");
				
				// Parse models
				for each(var model:Object in rawModels)
				{				
					trace("[CoreLoader] > Parsing model:", model.fileName);
					
					// Get filename without extension (since the file is in a directory of this name)
					var modelMaterialsDir:String = Utils.trimExtension(model.fileName);
					
					// Determine whether model data is binary (A3D, 3DS) or text (Collada)
					if(model.binary)
					{
						currentModels = modelParser.parseBinaryModel(
							ByteArray(model.modelData),
							model.dataFormat,
							Globals.LOCAL_ROOT + Globals.MATERIAL_DIR_MODELS + modelMaterialsDir + "/",
							library.animations
						);
					} else {						
						currentModels = modelParser.parseColladaModel(
							XML(model.modelData),
							Globals.LOCAL_ROOT + Globals.MATERIAL_DIR_MODELS + modelMaterialsDir + "/",
							library.animations,
							library.properties
						);
					}
					
					// Add each parsed model to the library
					for each(var item:Object3D in currentModels)
					{
						library.addObject(item);
					}
					
					trace("-------");
				}
				
				trace("[CoreLoader] > Parsing sprites..");
				
				// Parse sprites
				for each(var o:Object in _configs[0].sprites.sprite)
				{
					trace("[CoreLoader] > Parsing sprite:", o.@name);
					
					currentSprite = modelParser.parseSprite(
						o.@name,
						parseInt(o.@width),
						parseInt(o.@height),
						Globals.LOCAL_ROOT + Globals.SPRITE_DIR + o.@diffuseMap,
						Globals.LOCAL_ROOT + Globals.SPRITE_DIR + o.@opacityMap,
						parseFloat(o.@opacity)
					);
					
					// Add parsed sprite to the library
					library.addObject(currentSprite);
					
					trace("-------");
				}
				
				// Load materials
				modelParser.addEventListener(ProgressEvent.PROGRESS, onMaterialLoadingProgress, false, 0, true);
				modelParser.addEventListener(Event.COMPLETE, onMaterialLoadingComplete, false, 0, true);
				modelParser.loadMaterials();	
				
				assetLoadStatus.models = assetLoadStatus.sprites = true;
				onAssetLoadPartComplete();
				 
			} catch(e:Error) {
				trace("[CoreLoader] > Error cought: " + e.message + ".");
			}			
		}
		
		/**
		 * Called regulary when material loading is in progress.
		 * 
		 * @param e Event object.
		 */
		private function onMaterialLoadingProgress(e:ProgressEvent):void
		{
			trace("[CoreLoader] > Material", e.bytesLoaded, "of", e.bytesTotal, "loaded");
		}		
		
		/**
		 * Called when material loading is complete.
		 * 
		 * @param e Event object.
		 */
		private function onMaterialLoadingComplete(e:Event):void
		{
			(e.target as EventDispatcher).removeEventListener(ProgressEvent.PROGRESS, onMaterialLoadingProgress);
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onMaterialLoadingComplete);
			
			trace("[CoreLoader] > All materials loaded");
			
			assetLoadStatus.materials = true;
			onAssetLoadPartComplete();		
		}
		
		/**
		 * Dispatches CoreLoaderEvent.ASSETS_LOADED event if all assets are loaded.
		 * Resets corresponding progress tracking object after completion event is fired.
		 */
		private function onAssetLoadPartComplete():void
		{
			var result:Boolean = true;
			
			// Handle configs
			
			if(configsLoaded)
			{
				configsLoaded = false;
				dispatchEvent(new Event(CoreLoaderEvent.CONFIGS_LOADED));
				currentStep++;
				trace("[CoreLoader] > All configs loaded");	
			} else {
				
				currentStep = totalSteps;
				
				// Handle assets
				
				for each(var property:Boolean in assetLoadStatus)
				{
					// If at least one property is still false
					if(!property)
					{					
						result = false;
						currentStep--;					
					}		
				}
				
				// If everything is loaded
				if(result)
				{
					for each(property in assetLoadStatus)
					{
						property = false;
					}
					
					preloader.unfocus();
					dispatchEvent(new Event(CoreLoaderEvent.ASSETS_LOADED));				
					trace("[CoreLoader] > All assets loaded.");
				}
			}
			
			updatePreloaderStep();
		}
		
		/*---------------------------
		Map loading event callbacks
		---------------------------*/
		
		/**
		 * Fired after map geometry is loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapLoaded(e:Event):void
		{			
			var loader:MapLoader = MapLoader(e.currentTarget);
			var rawMap:Object = loader.loadedMapData;
			var mapParser:MapParser = new MapParser();
			var map:GameMap = new GameMap();
			
			loader.removeEventListener(Event.COMPLETE, onModelsLoaded);			
			
			try {							
				trace("[CoreLoader] > Parsing map:", rawMap.fileName);
				
				// Get filename without extension (since the file is in a directory of this name)
				var mapFilenameNoExtension:String = Utils.trimExtension(rawMap.fileName);
				
				// Determine whether map data is binary (A3D) or text (Collada) and parse				
				if(rawMap.binary)
				{
					// todo:binary
					/*mapParser.parseBinaryMap(
						ByteArray(map.modelData),
						map.dataFormat,
						Globals.LOCAL_ROOT + Globals.MATERIAL_DIR_MAPS + mapMaterialsDir + "/",
						library.animations
					);*/
				} else {						
					mapParser.parseColladaMap(
						map,
						XML(rawMap.mapData),
						Globals.LOCAL_ROOT + Globals.MATERIAL_DIR_MAPS + mapFilenameNoExtension + "/"
					);					
					map.name = mapFilenameNoExtension;
					map.init();
				}
				
				trace("-------");
				
				// Load materials
				mapParser.addEventListener(ProgressEvent.PROGRESS, onMapMaterialLoadingProgress, false, 0, true);
				mapParser.addEventListener(Event.COMPLETE, onMapMaterialLoadingComplete, false, 0, true);
				mapParser.loadMaterials();
				
				mapLoadStatus.geometry = true;
				onMapLoadPartComplete();
				
			} catch(e:Error) {
				trace("[CoreLoader] > Error cought: " + e.message + ".\n" + e.getStackTrace());
			}			
		}
		
		/**
		 * Called after each map material is loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapMaterialLoadingProgress(e:ProgressEvent):void
		{
			trace("[CoreLoader] > Map material", e.bytesLoaded, "of", e.bytesTotal, "loaded");
		}		
		
		/**
		 * Called when map materials are loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapMaterialLoadingComplete(e:Event):void
		{
			(e.target as EventDispatcher).removeEventListener(ProgressEvent.PROGRESS, onMaterialLoadingProgress);
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onMaterialLoadingComplete);
			
			trace("[CoreLoader] > All map materials loaded");
			
			mapLoadStatus.materials = true;
			onMapLoadPartComplete();		
		}
		
		/**
		 * Dispatches CoreLoaderEvent.ASSETS_LOADED event if all assets are loaded.
		 * Resets corresponding progress tracking object after completion event is fired.
		 */
		private function onMapLoadPartComplete():void
		{
			var result:Boolean = true;
			
			for each(var property:Boolean in mapLoadStatus)
			{
				// If at least one property is still false
				if(!property)
				{
					result = false;
				}
			}
			
			if(result)
			{
				for each(property in mapLoadStatus)
				{
					property = false;
				}
				
				dispatchEvent(new Event(CoreLoaderEvent.MAP_LOADED));
				trace("[CoreLoader] > Map loaded.");
			}
			
			result = true;
		}
		
		/**
		 * Updates preloader value.
		 */
		private function updatePreloaderStep():void
		{
			preloader.value = 100 / totalSteps * currentStep;
		}
	}
}