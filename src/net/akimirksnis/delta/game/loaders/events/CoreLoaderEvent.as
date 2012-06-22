package net.akimirksnis.delta.game.loaders.events
{
	import flash.events.Event;
	
	public class CoreLoaderEvent extends Event
	{
		public static const CONFIGS_LOADED:String = "configsLoaded";
		public static const ASSETS_LOADED:String = "assetsLoaded";
		public static const MAP_LOADED:String = "mapLoaded";
		
		public function CoreLoaderEvent(type:String, bubbles:Boolean = false, cancelable:Boolean = false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * Clones event object.
		 * 
		 * @return Cloned event object.
		 */
		override public function clone():Event
		{
			return new CoreLoaderEvent(type);
		}
	}
}