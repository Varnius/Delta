package net.akimirksnis.delta.game.gui.controllers
{
	import com.bit101.components.CheckBox;
	import com.bit101.components.Component;
	import com.bit101.components.InputText;
	import com.bit101.components.Overlay;
	import com.bit101.components.TextArea;
	import com.bit101.utils.MinimalConfigurator;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import net.akimirksnis.delta.game.gui.views.DebugOverlay;
	import net.akimirksnis.delta.game.utils.Globals;

	public class DebugOverlayController extends OverlayController
	{		
		public function DebugOverlayController(name:String)
		{
			super(DebugOverlay.view, name);
		}
		
		/*---------------------------
		Public functions
		---------------------------*/
		
		/*---------------------------
		Component event callbacks
		---------------------------*/
		
		/**
		 * Handles console input when submit button is pressed.
		 * @param e Event object.
		 */
		public function onConsoleSubmit(e:Event = null):void
		{			
			var consoleInput:InputText = minco.getCompById("console_input") as InputText;
			executeConsoleCommand(consoleInput.text);
			consoleInput.text = "";
		}
		
		/**
		 * Handles console input when its input field is in focus and ENTER is pressed.
		 * @param e Event object.
		 */
		private function onConsoleSubmitEnter(e:KeyboardEvent):void
		{
			// On ENTER press
			if(e.keyCode == 13)
			{
				onConsoleSubmit();
			}
		}
		
		/**
		 * Handles geometry debug menu input.
		 * @param e Event object.
		 */
		public function onGeometryDebugMenuSubmit(e:Event = null):void
		{
			(minco.getCompById("cb_show_terrain") as CheckBox).selected ? 
				executeConsoleCommand("show_terrain 1") : 
				executeConsoleCommand("show_terrain 0") ;
			(minco.getCompById("cb_show_terrain_wireframe") as CheckBox).selected ? 
				executeConsoleCommand("show_terrain_wireframe 1") : 
				executeConsoleCommand("show_terrain_wireframe 0") ;
			(minco.getCompById("cb_show_colmesh") as CheckBox).selected ? 
				executeConsoleCommand("show_colmesh 1") : 
				executeConsoleCommand("show_colmesh 0") ;
		}
		
		/**
		 * Handles unit debug menu input.
		 * @param e Event object.
		 */
		public function onUnitDebugMenuSubmit(e:Event = null):void
		{
			(minco.getCompById("cb_show_unit_boundboxes") as CheckBox).selected ? 
				executeConsoleCommand("show_unit_boundboxes 1") : 
				executeConsoleCommand("show_unit_boundboxes 0") ;
		}
		
		/**
		 * Handles lights debug menu input.
		 * @param e Event object.
		 */
		public function onLightsDebugMenuSubmit(e:Event = null):void
		{
			(minco.getCompById("cb_light_enable_ambient") as CheckBox).selected ? 
				executeConsoleCommand("light_enable_ambient 1") : 
				executeConsoleCommand("light_enable_ambient 0") ;
			(minco.getCompById("cb_light_enable_omni") as CheckBox).selected ? 
				executeConsoleCommand("light_enable_omni 1") : 
				executeConsoleCommand("light_enable_omni 0") ;
			(minco.getCompById("cb_light_enable_directional") as CheckBox).selected ? 
				executeConsoleCommand("light_enable_directional 1") : 
				executeConsoleCommand("light_enable_directional 0") ;
			(minco.getCompById("cb_light_enable_spot") as CheckBox).selected ? 
				executeConsoleCommand("light_enable_spot 1") : 
				executeConsoleCommand("light_enable_spot 0") ;
			(minco.getCompById("cb_show_light_sources") as CheckBox).selected ? 
				executeConsoleCommand("show_light_sources 1") : 
				executeConsoleCommand("show_light_sources 0") ;
		}
		
		/**
		 * Handles camera debug menu input.
		 * @param e Event object.
		 */
		public function onUseFreeRoamCameraSubmit(e:Event):void
		{
			executeConsoleCommand("use_camera_mode 2");
		}
		
		/**
		 * Handles camera debug menu input.
		 * @param e Event object.
		 */
		public function onUseStandartCameraSubmit(e:Event):void
		{
			executeConsoleCommand("use_camera_mode 1");
		}
		
		/**
		 * Submits all debug menus.
		 */
		public function submitDebugMenus():void
		{
			onGeometryDebugMenuSubmit();
			onUnitDebugMenuSubmit();
			onLightsDebugMenuSubmit();
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		private function executeConsoleCommand(command:String):void
		{			
			var message:String = Globals.gameCore.executeConsoleCommand(command);			
			TextArea(minco.getCompById("console_text")).text += command + "\n";
			
			if(message != "")
			{
				TextArea(minco.getCompById("console_text")).text += message + "\n";
			}
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
	}
}