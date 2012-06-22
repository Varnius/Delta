package net.akimirksnis.delta.game.utils
{
	import net.akimirksnis.delta.game.gui.controllers.DebugOverlayController;

	public class Logger
	{		
		public static var out:DebugOverlayController;
		
		public static function log(... args):void 
		{ 
			var output:String = "";
			
			for each(var o:* in args) 
			{ 
				output += o + " ";
			}
			
			if(out != null)
			{
				out.appendToConsole(output);
			}
		} 
	}
}