package net.akimirksnis.delta.game.loaders.loaders
{	
	import alternativa.types.Byte;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import net.akimirksnis.delta.game.loaders.parsers.BinaryModelFormat;
	
	public class ModelLoader extends EventDispatcher
	{
		protected  var _loadedData:Vector.<Object>;
		
		private var modelsToLoad:XMLList;
		private var modelPath:String;
		private var urlLoader:PimpedURLLoader;
		private var modelsTotal:int;
		private var modelsLoaded:int = 0;
		
		/**
		 * Class constructor.
		 * 
		 * @param modelPath Folder containing models.
		 * @param modelsToLoad A list of models.
		 */
		public function ModelLoader(modelPath:String, modelsToLoad:XMLList)
		{
			this.modelPath = modelPath;	
			this.modelsToLoad = modelsToLoad;
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Loads models listed in param XMLList.
		 * 
		 * @param modelsToLoad List of models to load.
		 */
		public function loadModels():void
		{			
			// Reset loader in case of reuse
			modelsLoaded = 0;
			_loadedData = new Vector.<Object>;	
			
			// Determine number of models to load
			modelsTotal = modelsToLoad.length();
			
			// Loop through models and load everything
			for each(var item:XML in modelsToLoad)
			{				
				// Geometry loader
				urlLoader = new PimpedURLLoader();
				
				// Get file extension
				var extension:String = String(item.@filename).substr(-3, 3).toLowerCase();
				
				// Determine file format
				switch(extension)
				{
					case BinaryModelFormat.DAE:
					{
						urlLoader.dataFormat = URLLoaderDataFormat.TEXT;
						break;
					}
					case BinaryModelFormat.A3D:
					{
						urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
						break;
					}
					case BinaryModelFormat.THREE_DS:
					{
						urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
						break;
					}
					default:
					{
						throw new Error("[ModelLoader] > Unknown file type: '" + extension +"'");
					}
				}
				
				// Load model geometry
				urlLoader.addEventListener(Event.COMPLETE, onEachModelLoaded);
				urlLoader.addEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
				urlLoader.load(new URLRequest(modelPath + item.@filename));
			}
			
			if(modelsTotal == 0)
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		/*---------------------------
		Event callbacks
		---------------------------*/

		private function onEachModelLoaded(e:Event):void
		{
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onEachModelLoaded);
			(e.target as EventDispatcher).removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
			
			modelsLoaded++;
			
			var loader:PimpedURLLoader = PimpedURLLoader(e.target);
			
			// Create result object
			var result:Object =
			{
				modelData: loader.data,
				fileName: loader.fileName,
				binary: loader.data is ByteArray ? true : false,
				dataFormat: String(loader.fileName).substr(-3, 3).toLowerCase()
			};				
			
			_loadedData.push(result);
			
			// If all models are loaded
			if(modelsLoaded == modelsTotal)
				onAllModelsLoaded();			
		}
		
		private function onLoadingError(e:ErrorEvent):void
		{
			// Remove unneeded event listeners
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onEachModelLoaded);
			(e.target as EventDispatcher).removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
			
			dispatchEvent(e);
		}
		
		private function onAllModelsLoaded():void
		{
			// Notify that loading is complete
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get loadedData():Vector.<Object>
		{
			if(modelsLoaded != modelsTotal)
			{
				throw new Error("[ModelLoader] > Error while loading model data.");
			}
			
			return _loadedData;
		}
	}
}