package net.akimirksnis.delta.game.net
{
	import flash.events.EventDispatcher;
	
	import net.akimirksnis.delta.game.controllers.interfaces.IController;
	import net.akimirksnis.delta.game.events.RemotePlayerEvent;
	import net.akimirksnis.delta.game.social.Social;
	import net.akimirksnis.delta.game.utils.Logger;
	
	import realtimelib.RealtimeChannelManager;
	import realtimelib.events.ConnectionStatusEvent;
	import realtimelib.events.DataReceivedEvent;
	import realtimelib.events.PeerStatusEvent;
	import realtimelib.events.StatusInfoEvent;
	import realtimelib.session.P2PSession;
	
	[Event(name="PlayerReady",type="net.akimirksnis.delta.game.events.RemotePlayerEvent")]
	[Event(name="PlayerUpdated",type="net.akimirksnis.delta.game.events.RemotePlayerEvent")]
	[Event(name="statusChange",type="flash.events.ConnectionStatusEvent")]
	
	/**
	 * Manages P2P connection for multiplayer.
	 */
	public class P2PController extends EventDispatcher implements IController
	{		
		private static var _instance:P2PController = new P2PController(SingletonLock);
		
		// Connection settings
		private const RTMFP_SERVER_ADDRESS:String = "rtmfp://p2p.rtmfp.net/";
		private const DEVELOPER_KEY:String = "744a67128e2758856d10f6e4-6f17628a0106";		

		private var _session:P2PSession;		
		private var _realtimeChannelManager:RealtimeChannelManager;
		
		/**
		 * Class constructor.
		 */
		public function P2PController(lock:Class)
		{
			// ..
		}
		
		/*---------------------------
		Public functions
		---------------------------*/
		
		public function joinSession(groupName:String):void
		{			
			_session = new P2PSession(RTMFP_SERVER_ADDRESS + DEVELOPER_KEY, groupName);			
			_session.addEventListener(ConnectionStatusEvent.STATUS_CHANGE, onSessionStatusChange, false, 0, true);
			_session.addEventListener(StatusInfoEvent.STATUS_INFO, onSessionStatusInfo, false, 0, true);			
			_session.connect(Social.username, new Object());
			
			Logger.log("Joining a session with username:", Social.username);
		}
		
		/**
		 * Ends current session.
		 */
		public function endSession():void
		{
			_session.close();
			_realtimeChannelManager.close();
			
			// Remove event listeners
			_session.removeEventListener(ConnectionStatusEvent.STATUS_CHANGE, onSessionStatusChange);
			_session.removeEventListener(StatusInfoEvent.STATUS_INFO, onSessionStatusInfo);
			_session.removeEventListener(PeerStatusEvent.USER_ADDED, onUserAdded);
			_session.removeEventListener(PeerStatusEvent.USER_REMOVED, onUserRemoved);
			_session.group.removeEventListener(DataReceivedEvent.DATA_RECEIVED, onIndividualDataReceived);
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/**
		 * Called after connection to group is established.
		 */
		protected function onConnectedToGroup():void
		{
			Logger.log("GroupAddr: ", _session.user.address);
			Logger.log("PeerID:    ", _session.user.id);
			
			// Create new channel manager
			_realtimeChannelManager = new RealtimeChannelManager(_session);
			
			// Add event listeners for game events
			_session.addEventListener(PeerStatusEvent.USER_ADDED, onUserAdded, false, 0, true);
			_session.addEventListener(PeerStatusEvent.USER_REMOVED, onUserRemoved, false, 0, true);
			
			// Add listener for getting received individual data
			_session.group.addEventListener(DataReceivedEvent.DATA_RECEIVED, onIndividualDataReceived, false, 0, true);
		}
		
		/*---------------------------
		Connection event handlers
		---------------------------*/
		
		/**
		 * Fired after session status changes.
		 * 
		 * @param e Event object.
		 */
		protected function onSessionStatusChange(e:ConnectionStatusEvent):void
		{
			//Logger.log("[P2P] >", e.status);
			
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
					break;
				}
				case ConnectionStatusEvent.FAILED:
				{
					break;
				}
			}
			
			// Redispatch for OnlineGameManager
			dispatchEvent(e);
		}
		
		/**
		 * Fired after some new info about current session is available.
		 * 
		 * @param e Event object.
		 */
		protected function onSessionStatusInfo(e:StatusInfoEvent):void
		{
			Logger.log(e.message);
		}
		
		/*---------------------------
		Game event handlers
		---------------------------*/
		
		protected function onUserAdded(e:PeerStatusEvent):void
		{
			Logger.log("User added. Current user count:", _session.group.estimatedMemberCount);
			
			// If added user is not self
			if(e.user.id != _session.user.id)
			{
				_realtimeChannelManager.addRealtimeChannel(e.user.id, this);
			}
		}
		
		protected function onUserRemoved(e:PeerStatusEvent):void
		{
			Logger.log("User disconnected. Current user count:", _session.group.estimatedMemberCount);
			
			if(e.user.id != _session.user.id)
			{
				_realtimeChannelManager.removeRealtimeChannel(e.user.id);
			}
		}
		
		/*---------------------------
		Send/receive helpers
		---------------------------*/
		
		/*----------------
		> Send individual data
		----------------*/
		
		public var receiveIndividualDataCallback:Function;
		
		/**
		 * Send data (as object) to individual peer, defined by peerID.
		 * 
		 * @param peerID PeerID.
		 * @param data Data object.
		 */
		public function sendIndividualData(peerID:String, data:Object):void
		{
			session.sendIndividualData(peerID, data);
		}
		public function onIndividualDataReceived(e:DataReceivedEvent):void
		{
			receiveIndividualDataCallback(e.data);
		}
		
		/*----------------
		> Send data
		----------------*/
		
		public var receiveDataCallback:Function;
		
		/**
		 * Send data (as object) to all peers.
		 * 
		 * @param data Data object.
		 */
		public function sendData(data:Object):void
		{
			_realtimeChannelManager.sendStream.send("receiveData", _session.user.id, data);
		}
		public function receiveData(peerID:String, data:Object):void
		{
			//receiveDataCallback(data);
		}	
		
		/*----------------
		> PlayerReady
		----------------*/
		
		public var receivePlayerReadyCallback:Function;
		
		/**
		 * Informs all peers that this player is ready to play.
		 * That means that all client side processing (like loading map) here is done.
		 */
		public function sendPlayerReady():void
		{
			_realtimeChannelManager.sendStream.send("receivePlayerReady", _session.user.id);
		}
		public function receivePlayerReady(peerID:String):void
		{
			receivePlayerReadyCallback(peerID);
		}	
		
		/*----------------
		> PlayerNotReady
		----------------*/

		public function sendString(string:String):void
		{
			_realtimeChannelManager.sendStream.send("receiveString", _session.user.id, string);
		}
		public function receiveString(peerID:String, string:String):void
		{
			Logger.log("Received", string);
		}	
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Returns singleton of this class.
		 */
		public static function get instance():P2PController
		{			
			return _instance;
		}
		
		/**
		 * @inherit
		 */
		public function get enabled():Boolean
		{
			return true;
		}
		public function set enabled(enabled:Boolean):void
		{
			// ..
		}
		
		/**
		 * Current P2P session.
		 */
		public function get session():P2PSession
		{
			return _session;
		}
	}
}

class SingletonLock {}