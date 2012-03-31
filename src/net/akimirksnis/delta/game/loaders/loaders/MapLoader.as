package net.akimirksnis.delta.game.loaders.loaders
{	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;

	public class MapLoader extends EventDispatcher
	{
		private var _mapsPath:String;
		private var _mapData:XML;
		
		public function MapLoader(mapsPath:String)
		{
			_mapsPath = mapsPath;
		}
		
		public function loadMap(mapFile:String):void
		{
			var loader:PimpedURLLoader = new PimpedURLLoader();
			loader.addEventListener(Event.COMPLETE, onMapLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
			loader.load(new URLRequest(_mapsPath + mapFile));
		}
		
		private function onMapLoaded(e:Event):void
		{
			// Remove unneeded event listeners
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onMapLoaded);
			(e.target as EventDispatcher).removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
			
			_mapData = XML((e.target as PimpedURLLoader).data);
			dispatchEvent(new Event(Event.COMPLETE));
		}
		
		private function onLoadingError(e:ErrorEvent):void
		{
			// Remove unneeded event listeners
			(e.target as EventDispatcher).removeEventListener(Event.COMPLETE, onMapLoaded);
			(e.target as EventDispatcher).removeEventListener(IOErrorEvent.IO_ERROR, onLoadingError);
			
			dispatchEvent(e);
		}
		
		public function get mapData():XML
		{
			return _mapData;
		}
	}
}