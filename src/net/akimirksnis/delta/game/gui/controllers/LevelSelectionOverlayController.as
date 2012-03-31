package net.akimirksnis.delta.game.gui.controllers
{
	import net.akimirksnis.delta.game.gui.views.LevelSelectionOverlay;

	public class LevelSelectionOverlayController extends OverlayController
	{
		private var _levelData:Vector.<Object>;
		
		public function LevelSelectionOverlayController(name:String)
		{
			super(LevelSelectionOverlay.view, name);
		}
		
		/*---------------------------
		Public functions
		---------------------------*/
		
		/*---------------------------
		Component event callbacks
		---------------------------*/
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/*---------------------------
		Getters/setters
		---------------------------*/		
		
		/**
		 * A collection of objects, each defining level data.
		 */
		public function get levelData():Vector.<Object>
		{
			return _levelData;
		}
		public function set levelData(value:Vector.<Object>):void
		{
			_levelData = value;
		}
	}
}