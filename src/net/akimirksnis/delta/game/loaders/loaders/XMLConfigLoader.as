package net.akimirksnis.delta.game.loaders.loaders
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.URLRequest;
	
	public class XMLConfigLoader extends EventDispatcher
	{
		private var _loadedData:Vector.<XML>;
		private var itemsTotal:int;
		private var itemsLoaded:int = 0;
		
		public function XMLConfigLoader() {}
		
		public function load(configsToLoad:Array):void
		{
			// Reset loader
			itemsLoaded = 0;
			itemsTotal = configsToLoad.length;
			_loadedData = new Vector.<XML>;
			
			// Load XML files
			for each(var filePath:String in configsToLoad)
			{
				var loader:PimpedURLLoader = new PimpedURLLoader();
				loader.addEventListener(Event.COMPLETE, onFileLoad);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
				loader.load(new URLRequest(filePath));
			}		
		}
		
		private function onFileLoad(e:Event):void
		{
			// Remove unneeded event listeners
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onFileLoad);
			(e.target as EventDispatcher).removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			itemsLoaded++;
			
			// Notify about loading progress (1 ProgressEvent per loaded file)
			var progressEvent:ProgressEvent = new ProgressEvent(ProgressEvent.PROGRESS);
			progressEvent.bytesLoaded = itemsLoaded;
			progressEvent.bytesTotal = itemsTotal;
			dispatchEvent(progressEvent);
			
			// Push file data
			_loadedData.push(new XML((e.target as PimpedURLLoader).data));
			
			// Debug
			trace("[XMLLoader] Loaded XML file: " + (e.target as PimpedURLLoader).fileName);
			
			// If all files are loaded
			if(itemsLoaded == itemsTotal)
				onAllFilesLoaded();
		}
		
		private function onFileLoadError(e:IOErrorEvent):void
		{
			// Remove unneeded event listeners
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onFileLoad);
			(e.target as EventDispatcher).removeEventListener(IOErrorEvent.IO_ERROR, onFileLoadError);
			
			dispatchEvent(e);
		}
		
		private function onAllFilesLoaded():void
		{
			// Notify that loading is complete
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		public function get loadedData():Vector.<XML>
		{
			return _loadedData;
		}
	}
}