package net.akimirksnis.delta.game.loaders.events
{
	import flash.events.Event;
	
	public class CoreLoaderEvent extends Event
	{
		public static const CONFIGS_LOADED:String = "configs_loaded";
		public static const ASSETS_LOADED:String = "assets_loaded";
		public static const MAP_LOADED:String = "map_loaded";
		
		public function CoreLoaderEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}