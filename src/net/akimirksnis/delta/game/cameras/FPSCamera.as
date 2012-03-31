package net.akimirksnis.delta.game.cameras
{
	import alternativa.engine3d.core.Camera3D;
	import alternativa.engine3d.core.View;
	
	import net.akimirksnis.delta.game.utils.*;
	
	public class FPSCamera extends Camera3D
	{
		// Clipping properties
		public static const NEAR_CLIPPING:Number = 0.1;
		public static const FAR_CLIPPING:Number = 100000;
		
		// Background color and alpha
		public static const BACKGROUND_COLOR:uint = 0x000000;
		public static const BACKGROUND_ALPHA:Number = 0;
		
		// Rotation
		public static const ROTATION_X:Number = Utils.degToRad(-90);
		public static const ROTATION_Y:Number = 0;
		public static const ROTATION_Z:Number = Utils.degToRad(180);
		
		public function FPSCamera()
		{
			super(NEAR_CLIPPING, FAR_CLIPPING);			
			view = new View(Globals.stage.stageWidth, Globals.stage.stageHeight, false, BACKGROUND_COLOR, BACKGROUND_ALPHA);
			
			// Set default camera orientation
			rotationX = ROTATION_X;
			rotationY = ROTATION_Y;
			rotationZ = ROTATION_Z;
			
			// Remove Alternativa context menu
			view.contextMenu = null;			
			// Hide Alternativa logo
			view.hideLogo();
			
			// Debug
			diagramHorizontalMargin = 10;
			diagramVerticalMargin = 10;
			
			// Enable camera debug mode
			this.debug = true;
		}
	}
}