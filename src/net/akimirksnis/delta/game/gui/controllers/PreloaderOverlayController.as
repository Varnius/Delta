package net.akimirksnis.delta.game.gui.controllers
{
	import com.bit101.components.Label;
	import com.bit101.components.ProgressBar;
	
	import net.akimirksnis.delta.game.gui.views.PreloaderOverlay;
	
	public class PreloaderOverlayController extends OverlayController
	{
		private var progressBar:ProgressBar;
		private var label:Label;
		
		public function PreloaderOverlayController(name:String)
		{
			super(PreloaderOverlay.view, name);
			progressBar = ProgressBar(minco.getCompById("ProgressBar"));
			label = Label(minco.getCompById("ProgressLabel"));
			reset();
		}
		
		/*---------------------------
		Public functions
		---------------------------*/
		
		public function reset():void
		{
			progressBar.value = 0;
			progressBar.maximum = 100;
			label.text = "";
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get value():Number
		{
			return progressBar.value;
		}
		public function set value(value:Number):void
		{
			progressBar.value = value;
		}
		
		public function get max():Number
		{
			return progressBar.maximum;
		}
		public function set max(value:Number):void
		{
			progressBar.maximum = value;
		}
		
		public function get text():String
		{
			return label.text;
		}
		public function set text(value:String):void
		{
			label.text = value;
		}
	}
}