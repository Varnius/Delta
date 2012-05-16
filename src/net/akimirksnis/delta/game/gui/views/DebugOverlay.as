package net.akimirksnis.delta.game.gui.views
{
	public class DebugOverlay extends View
	{
		public static const view:XML =
			<comps>
				<Overlay id="debug_overlay" title="Debug options" color="0x222222" backgroundAlpha="0.25" multiFocusEnabled="true">
			
					<!-- Console -->
					<Window id="console_window" title="Console" x="5" y="5" width="500" height="300" draggable="true">
						<VBox left="5" right="5" top="5" bottom="5">
							<TextArea id="console_text" left="0" right="0" top="0" bottom="45" stickToBottom="true" />
							<HBox bottom="5" left="0" right="0">
								<InputText id="console_input" left="0" right="105" event="keyUp:onConsoleSubmitEnter"/>
								<PushButton label="Submit" right="0" event="click:onConsoleSubmit"/>
							</HBox>
						</VBox>
					</Window>
			
					<!-- Geometry debug menu -->
					<Window id="map_geometry_debug_menu" title="Debug map" width="200" height="190" left="5" bottom="5" draggable="true">
						<VBox left="15" right="5" top="15" bottom="15" spacing="13">
							<CheckBox label="Show terrain" id="cb_show_terrain" selected="true" />
							<CheckBox label="Show terrain wireframe" id="cb_show_terrain_wireframe" selected="false"/>
							<CheckBox label="Show collision mesh wireframe" id="cb_show_colmesh_wireframe" selected="false" />
							<CheckBox label="Show wireframes of generic meshes" id="cb_show_generic_wireframe" selected="false" />
							<HBox bottom="5" left="5" right="5">
								<PushButton label="Submit" right="0" event="click:onGeometryDebugMenuSubmit" />
							</HBox>
						</VBox>
					</Window>
			
					<!-- Lights debug menu -->
					<Window id="lights_debug_menu" title="Debug lights" width="200" height="190" left="210" bottom="5" draggable="true">
						<VBox left="15" right="15" top="15" bottom="15" spacing="13">
							<CheckBox label="Enable ambient lights" selected="true" id="cb_light_enable_ambient" />
							<CheckBox label="Enable omni lights" selected="true" id="cb_light_enable_omni" />
							<CheckBox label="Enable spot lights" selected="true" id="cb_light_enable_spot" />
							<CheckBox label="Enable directional lights" selected="true" id="cb_light_enable_directional" />
							<CheckBox label="Show light sources" selected="true" id="cb_show_light_sources" />
							<HBox bottom="5" left="5" right="5">
								<PushButton label="Submit" right="0" event="click:onLightsDebugMenuSubmit" />
							</HBox>
						</VBox>						
					</Window>
					
					<!-- Unit debug menu -->
					<Window id="unit_debug_menu" title="Debug units" width="200" height="190" left="415" bottom="5" draggable="true">
						<VBox left="15" right="15" top="15" bottom="15" spacing="13">
							<CheckBox label="Show unit boundboxes" selected="true" id="cb_show_unit_boundboxes" />
							<HBox bottom="5" left="5" right="5">
								<PushButton label="Submit" right="0" event="click:onUnitDebugMenuSubmit" />
							</HBox>
						</VBox>						
					</Window>
			
					<!-- Octree debug menu -->
					<Window id="octree_debug_menu" title="Debug octrees" width="200" height="190" left="620" bottom="5" draggable="true">
						<VBox left="15" right="5" top="15" bottom="15" spacing="13">
							<CheckBox label="Show static octree" id="cb_show_static_octree" selected="false" />
							<CheckBox label="Show dynamic octree" id="cb_show_dynamic_octree" selected="false" />
							<HBox bottom="5" left="5" right="5">
								<PushButton label="Submit" right="0" event="click:onOctreeDebugMenuSubmit" />
							</HBox>
						</VBox>
					</Window>
			
					<!-- Camera debug menu -->
					<Window id="camera_debug_menu" title="Camera mode" width="120" height="190" left="825" bottom="5" draggable="true" hasMinimizeButton="true">
						<VBox bottom="5" left="5" right="5" top="5">
							<PushButton label="Free Roam" right="0" event="click:onUseFreeRoamCameraSubmit" />
							<PushButton label="FPS" right="0" event="click:onUseStandartCameraSubmit" />
						</VBox>					
					</Window>
			
					<!-- Hierarchy -->
					<Window title="Level hierarchy" right="5" top="5" width="500" height="300" draggable="true" hasMinimizeButton="false">
						<VBox bottom="25" left="5" right="5" top="5">
							<TextArea id="textarea-hierarchy" html="true" editable="false" top="0" left="0" bottom="0" right="0"/>
						</VBox>	
					</Window>
			
				</Overlay>
			</comps>;
	}
}