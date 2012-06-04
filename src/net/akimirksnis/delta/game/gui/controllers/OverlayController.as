package net.akimirksnis.delta.game.gui.controllers
{
	import net.akimirksnis.delta.game.gui.GuiController;
	
	/**
	 * Base class for overlay controllers.
	 */
	public class OverlayController extends ComponentController
	{		
		public function OverlayController(view:XML, name:String)
		{
			super(view, name);
		}
		
		/*---------------------------
		Public functions
		---------------------------*/

		/**
		 * Focus controller.
		 */
		public function focus():void
		{
			// Make global instance of GuiController focus this overlay
			GuiController.instance.focusOverlay(name);
		}
		
		/**
		 * Unfocus controller.
		 */
		public function unfocus():void
		{
			GuiController.instance.unfocusOverlay(name);
		}	
	}
}