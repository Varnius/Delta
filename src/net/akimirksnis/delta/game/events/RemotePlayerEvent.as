package net.akimirksnis.delta.game.events
{
	import flash.events.Event;
	
	/**
	 * Defines remote player associated event.
	 */
	public class RemotePlayerEvent extends Event
	{
		public static const PLAYER_READY:String = "PlayerReady";
		public static const PLAYER_UPDATED:String = "PlayerUpdated";		
		
		private var _peerID:String;
		
		/**
		 * Creates an event object.
		 * 
		 * @param type Event type.
		 * @param peerID PeerID of a player given by active NetConnection.
		 */
		public function RemotePlayerEvent(type:String, peerID:String)
		{
			super(type, false, false);
			
			_peerID = peerID;
		}
		
		/**
		 * PeerID of associated player.
		 */
		public function get playerID():String
		{
			return _peerID;
		}
		
		/**
		 * Clones event object.
		 * 
		 * @return Cloned event object.
		 */
		override public function clone():Event
		{
			return new RemotePlayerEvent(type, _peerID);
		}
	}
}