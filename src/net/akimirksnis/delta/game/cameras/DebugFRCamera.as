package net.akimirksnis.delta.game.cameras
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;	
	import net.akimirksnis.delta.game.utils.*;

	public class DebugFRCamera extends Camera3D
	{ 
		// Clipping properties
		public const NEAR_CLIPPING:Number = 0.1;
		public const FAR_CLIPPING:Number = 100000;
		
		// Background color and alpha
		public const BACKGROUND_COLOR:uint = 0x000000;
		public const BACKGROUND_ALPHA:Number = 0;
		
		public function DebugFRCamera()
		{
			super(NEAR_CLIPPING, FAR_CLIPPING);
			
			view = new View(Globals.stage.stageWidth, Globals.stage.stageHeight, false, BACKGROUND_COLOR, BACKGROUND_ALPHA);
			
			// Remove Alternativa context menu
			view.contextMenu = null;			
			// Hide Alternativa logo
			view.hideLogo();
			
			// Set default camera orientation
			rotationX = Utils.degToRad(-160);
			y = -600;
			z = 1200;
			
			// Debug
			diagramHorizontalMargin = 10;
			diagramVerticalMargin = 30;
		}
	}
}