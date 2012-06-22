package net.akimirksnis.delta.game.gui.controllers
{
	import com.bit101.components.List;
	
	import flash.events.Event;
	
	import net.akimirksnis.delta.game.gui.components.LevelListItem;
	import net.akimirksnis.delta.game.gui.views.LevelSelectionOverlay;
	import net.akimirksnis.delta.game.utils.Globals;

	public class LevelSelectionOverlayController extends OverlayController
	{
		private var levelList:List;
		
		public function LevelSelectionOverlayController(name:String)
		{
			super(LevelSelectionOverlay.view, name);
			
			levelList = List(minco.getCompById("LevelList"));
			levelList.listItemClass = LevelListItem;
		}
		
		/*---------------------------
		Public functions
		---------------------------*/
		
		/*---------------------------
		Component event callbacks
		---------------------------*/
		
		public function onCreateGameButtonClick(e:Event):void
		{
			Globals.gameCore.executeCommand("create_game " + levelList.selectedItem.filename);
		}
		
		public function onJoinGameButtonClick(e:Event):void
		{
			Globals.gameCore.executeCommand("join_game 4ag4j4a987h41agasg7fh77yyklj8l74");
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/*---------------------------
		Getters/setters
		---------------------------*/		
		
		/**
		 * A collection of objects, each defining level data.
		 */
		public function get mapData():Array
		{
			return levelList.items;
		}
		public function set mapData(value:Array):void
		{			
			// Clone array
			levelList.items = value.concat();
		}
	}
}