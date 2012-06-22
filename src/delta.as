package
{
	import flash.display.*;
	
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.utils.Globals;
	
	[SWF(width="1280", height="720", frameRate="60")]
	public class delta extends Sprite
	{
		public function delta()
		{
			// Set stage properties [currently debugging in standalone player]
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			
			Globals.stage = stage;
			Globals.stage3D = stage.stage3Ds[0];
			
			var core:Core = Core.instance;
			core.init();
		}
	}
}