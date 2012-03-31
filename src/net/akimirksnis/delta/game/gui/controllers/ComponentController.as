package net.akimirksnis.delta.game.gui.controllers
{
	import com.bit101.components.Component;
	import com.bit101.utils.MinimalConfigurator;

	public class ComponentController
	{
		protected var minco:MinimalConfigurator = new MinimalConfigurator(this);
		protected var _component:Component;
		private var _enabled:Boolean = true;
		private var _name:String;
		
		public function ComponentController(view:XML, name:String)
		{			
			_component = Component(minco.parseSingleComponent(view));
			_name = name;
		}
		
		/*---------------------------
		Public functions
		---------------------------*/
		
		public function invalidateView():void
		{
			_component.draw();
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get component():Component
		{
			return _component;
		}
		
		public function get name():String
		{
			return _name;
		}
		
		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled(value:Boolean):void
		{
			_component.visible = value;
			_enabled = value;
		}
	}
}