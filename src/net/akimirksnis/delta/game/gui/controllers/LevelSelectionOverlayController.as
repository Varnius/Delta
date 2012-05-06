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
		
		public function onLoadButtonClick(e:Event):void
		{
			Globals.gameCore.executeCommand("loadmap " + levelList.selectedItem.filename);
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