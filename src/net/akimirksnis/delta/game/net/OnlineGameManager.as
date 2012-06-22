package net.akimirksnis.delta.game.net
{	
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.delta_internal;
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.units.UnitType;
	import net.akimirksnis.delta.game.entities.units.Walker2;
	import net.akimirksnis.delta.game.loaders.events.CoreLoaderEvent;
	import net.akimirksnis.delta.game.utils.Logger;
	
	import realtimelib.events.ConnectionStatusEvent;
	import realtimelib.events.PeerStatusEvent;

	use namespace delta_internal;
	
	/**
	 * Manages online game sessions and player proxies.
	 */
	public class OnlineGameManager
	{
		private static var _instance:OnlineGameManager = new OnlineGameManager(SingletonLock);
		
		private var _netController:P2PController;
		
		private var mapToLoad:String;
		private var gameActive:Boolean = false;
		private var players:Dictionary;
		private var proxies:Dictionary;
		
		/**
		 * Class constructor.
		 * 
		 * @param lock Lock class.
		 */
		public function OnlineGameManager(lock:Class)
		{
			// ..
		}		
		
		/*---------------------------
		Online game group creation
		---------------------------*/
		
		/**
		 * Joins an online game or creates a new one if sessionID points to non-existing session.
		 * 
		 * @param session Session ID.
		 * @param Map filename with extension. 
		 */		
		delta_internal function joinOnlineGame(groupName:String, mapFilename:String = null):void
		{
			if(!gameActive)
			{
				mapToLoad = mapFilename;
				
				Core.instance.loader.addEventListener(CoreLoaderEvent.MAP_LOADED, onMapLoaded, false, 0, true);				
				_netController.addEventListener(ConnectionStatusEvent.STATUS_CHANGE, onNetStatusChange, false, 0, true);				
				_netController.joinSession(groupName);	
				
				gameActive = true;
			} else {
				Logger.log("[OnlineGameManager] > Game is already active.");
			}
		}
		
		/**
		 * Disconnects current online game.
		 */
		delta_internal function disconnectOnlineGame():void
		{
			if(gameActive)
			{
				gameActive = false;
				_netController.endSession();
				
				_netController.session.removeEventListener(PeerStatusEvent.USER_ADDED, onPlayerAdded);
				_netController.session.removeEventListener(PeerStatusEvent.USER_REMOVED, onPlayerRemoved);
				_netController.removeEventListener(ConnectionStatusEvent.STATUS_CHANGE, onNetStatusChange);				
				
				Core.instance.loader.removeEventListener(CoreLoaderEvent.MAP_LOADED, onMapLoaded);
				Core.instance.executeCommand("unloadmap");			
			}			
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		/**
		 * Called when NetConnection status changes.
		 * 
		 * @param e Event object.
		 */
		private function onNetStatusChange(e:ConnectionStatusEvent):void
		{
			// Take a look at current status of the session
			switch(e.status)
			{
				case ConnectionStatusEvent.CONNECTING:
				{
					break;
				}
				case ConnectionStatusEvent.CONNECTED:
				{
					break;
				}
				case ConnectionStatusEvent.CONNECTED_TO_GROUP:
				{
					onConnectedToGroup();
					break;
				}				
				case ConnectionStatusEvent.DISCONNECTED:
				{
					trace('disconnected');
					break;
				}
				case ConnectionStatusEvent.FAILED:
				{
					trace('failed');
					break;
				}
			}
		}		
		
		/**
		 * Called when the connection to group is established.
		 */
		private function onConnectedToGroup():void
		{
			players = new Dictionary();
			proxies = new Dictionary();
			
			_netController.session.addEventListener(PeerStatusEvent.USER_ADDED, onPlayerAdded, false, 0, true);
			_netController.session.addEventListener(PeerStatusEvent.USER_REMOVED, onPlayerRemoved, false, 0, true);
			
			// If creating a new game session
			if(mapToLoad != null)
			{
				Core.instance.executeCommand("loadmap " + mapToLoad);
			} else {
				// todo: Set timer for "get timer info" timeout
			}
		}
		
		/**
		 * Called when map is loaded.
		 * 
		 * @param e Event object.
		 */
		private function onMapLoaded(e:CoreLoaderEvent):void
		{
			_netController.sendPlayerReady();
		}
		
		/**
		 * Called when player is added.
		 * 
		 * @param e Event object.
		 */
		private function onPlayerAdded(e:PeerStatusEvent):void
		{
			players[e.user.id] = e.user;

			// If not self
			if(e.user.id != _netController.session.user.id)
			{
				// Send map info to joining player if this peer has the map loaded
				if(GameMap.currentMap != null)
				{				
					var mapInfo:Object =
						{
							type: "mapInfo",
							mapName: GameMap.currentMap.name + "." + GameMap.currentMap.extension,
							mapHash: "none"
						};
					
					Logger.log("Sending map info to: ", e.user.id);
					
					_netController.sendIndividualData(e.user.id, mapInfo);
				}
			}						
		}
		
		/**
		 * Called after player is removed.
		 * 
		 * @param e Event object.
		 */
		private function onPlayerRemoved(e:PeerStatusEvent):void
		{
			delete players[e.user.id];
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/**
		 * Called when this peer receives any individual data.
		 * 
		 * @param data Data object.
		 */
		private function receiveIndividualData(data:Object):void
		{
			Logger.log('Individual data received with type:', data.type);
			
			switch(data.type)
			{
				case "mapInfo":
				{
					mapToLoad = data.mapName;
					Core.instance.executeCommand("loadmap " + mapToLoad);
					break;
				}
			}
		}
		
		/**
		 * Called when data sent by some pper to all others is available.
		 *
		 * @param data Data object.
		 */
		private function receiveData(data:Object):void
		{
			//
		}
		
		/**
		 * Called when remote player is ready to play.
		 * 
		 * @param peerID PeerID of the player.
		 * @param unitType Unit type chosen by player.
		 * @param playerTean ID of player team (todo: implement).
		 */
		protected function receivePlayerReady(peerID:String, unitType:String):void
		{
			Logger.log('Player ready:', peerID);
			
			var proxy:Unit;
			
			// Create a proxy for the remote player
			switch(unitType)
			{
				case UnitType.WALKER:
				{
					proxy = new Walker2();
					proxy.proxyModeEnabled = true;
					proxies[peerID] = proxy;
					GameMap.currentMap.addEntity(proxy, "marker-spawn1");
					
					break;
				}
			}			
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Returns singleton of this class.
		 */
		public static function get instance():OnlineGameManager
		{			
			return _instance;
		}
		
		public function set netController(value:P2PController):void
		{
			_netController = value;
			
			// Set NetController callbacks for game events
			_netController.receiveIndividualDataCallback = receiveIndividualData;
			_netController.receiveDataCallback = receiveData;
			_netController.receivePlayerReadyCallback = receivePlayerReady;
		}
	}
}

class SingletonLock {}