package net.akimirksnis.delta.game.gui.controllers
{
	import alternativa.engine3d.core.Object3D;
	
	import com.bit101.components.CheckBox;
	import com.bit101.components.InputText;
	import com.bit101.components.TextArea;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.core.GameMap;
	import net.akimirksnis.delta.game.entities.DynamicEntity;
	import net.akimirksnis.delta.game.gui.views.DebugOverlay;
	import net.akimirksnis.delta.game.utils.Logger;
	import net.akimirksnis.delta.game.utils.Utils;

	public class DebugOverlayController extends OverlayController
	{		
		private var consoleTextArea:TextArea;
		private var consoleInputText:InputText;
		
		public function DebugOverlayController(name:String)
		{
			super(DebugOverlay.view, name);
			
			consoleTextArea = TextArea(minco.getCompById("console_text"));
			consoleInputText = InputText(minco.getCompById("console_input"));
			
			// Set logger output target
			Logger.out = this;
			
			Core.instance.addEventListener("command_executed", onCommandExecuted);			
		}
		
		/*---------------------------
		Public functions
		---------------------------*/	
		
		/*---------------------------
		Event callbacks
		---------------------------*/
		
		public function onCommandExecuted(e:Event):void
		{
			consoleTextArea.text += Core.instance.lastResponse.length > 0 ? Core.instance.lastResponse.length + "\n" : "";
		}
		
		public function appendToConsole(s:String):void
		{
			consoleTextArea.text += s + "\n";
		}
		
		private function onMapHierarchyChanged(e:Event = null):void
		{
			TextArea(minco.getCompById("textarea-hierarchy")).textField.htmlText = GameMap.currentMap.hierarchyText;
		}
		
		/*---------------------------
		Component event callbacks
		---------------------------*/
		
		/**
		 * Handles console input when submit button is pressed.
		 * @param e Event object.
		 */
		public function onConsoleSubmit(e:Event = null):void
		{			
			Core.instance.executeCommand(consoleInputText.text);
			consoleInputText.text = "";
		}
		
		/**
		 * Handles console input when its input field is in focus and ENTER is pressed.
		 * @param e Event object.
		 */
		public function onConsoleSubmitEnter(e:KeyboardEvent):void
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
				Core.instance.executeCommand("show_terrain 1") : 
				Core.instance.executeCommand("show_terrain 0") ;
			(minco.getCompById("cb_show_terrain_wireframe") as CheckBox).selected ? 
				Core.instance.executeCommand("show_terrain_wireframe 1") : 
				Core.instance.executeCommand("show_terrain_wireframe 0") ;
			(minco.getCompById("cb_show_colmesh_wireframe") as CheckBox).selected ? 
				Core.instance.executeCommand("show_colmesh_wireframe 1") : 
				Core.instance.executeCommand("show_colmesh_wireframe 0") ;
			(minco.getCompById("cb_show_generic_wireframe") as CheckBox).selected ? 
				Core.instance.executeCommand("show_generic_wireframe 1") : 
				Core.instance.executeCommand("show_generic_wireframe 0") ;
		}
		
		/**
		 * Handles octree debug menu input.
		 * @param e Event object.
		 */
		public function onOctreeDebugMenuSubmit(e:Event = null):void
		{
			(minco.getCompById("cb_show_static_octree") as CheckBox).selected ? 
				Core.instance.executeCommand("show_static_octree 1") : 
				Core.instance.executeCommand("show_static_octree 0") ;
			(minco.getCompById("cb_show_dynamic_octree") as CheckBox).selected ? 
				Core.instance.executeCommand("show_dynamic_octree 1") : 
				Core.instance.executeCommand("show_dynamic_octree 0") ;
		}
		
		/**
		 * Handles unit debug menu input.
		 * @param e Event object.
		 */
		public function onUnitDebugMenuSubmit(e:Event = null):void
		{
			(minco.getCompById("cb_show_unit_boundboxes") as CheckBox).selected ? 
				Core.instance.executeCommand("show_unit_boundboxes 1") : 
				Core.instance.executeCommand("show_unit_boundboxes 0") ;
		}
		
		/**
		 * Handles lights debug menu input.
		 * @param e Event object.
		 */
		public function onLightsDebugMenuSubmit(e:Event = null):void
		{
			(minco.getCompById("cb_light_enable_ambient") as CheckBox).selected ? 
				Core.instance.executeCommand("light_enable_ambient 1") : 
				Core.instance.executeCommand("light_enable_ambient 0") ;
			(minco.getCompById("cb_light_enable_omni") as CheckBox).selected ? 
				Core.instance.executeCommand("light_enable_omni 1") : 
				Core.instance.executeCommand("light_enable_omni 0") ;
			(minco.getCompById("cb_light_enable_directional") as CheckBox).selected ? 
				Core.instance.executeCommand("light_enable_directional 1") : 
				Core.instance.executeCommand("light_enable_directional 0") ;
			(minco.getCompById("cb_light_enable_spot") as CheckBox).selected ? 
				Core.instance.executeCommand("light_enable_spot 1") : 
				Core.instance.executeCommand("light_enable_spot 0") ;
			(minco.getCompById("cb_show_light_sources") as CheckBox).selected ? 
				Core.instance.executeCommand("show_light_sources 1") : 
				Core.instance.executeCommand("show_light_sources 0") ;
		}
		
		/**
		 * Handles camera debug menu input.
		 * @param e Event object.
		 */
		public function onUseFreeRoamCameraSubmit(e:Event):void
		{
			Core.instance.executeCommand("use_camera_mode 2");
		}
		
		/**
		 * Handles camera debug menu input.
		 * @param e Event object.
		 */
		public function onUseStandartCameraSubmit(e:Event):void
		{
			Core.instance.executeCommand("use_camera_mode 1");
		}
		
		/*---------------------------
		Helpers
		---------------------------*/	
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function set hierarchyWindowSource(value:Object3D):void
		{
			if(value != null)
			{
				if(value is GameMap)
				{
					value.addEventListener(GameMap.HIERARCHY_CHANGED, onMapHierarchyChanged, false, 0, true);
					onMapHierarchyChanged();
				} else {
					TextArea(minco.getCompById("textarea-hierarchy")).textField.htmlText = Utils.getColoredHierarchyAsHTMLString(value, DynamicEntity);
				}				
				
			} else {
				TextArea(minco.getCompById("textarea-hierarchy")).textField.htmlText = "";
			}
		}
	}
}