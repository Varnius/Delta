package net.akimirksnis.delta.game.core
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.objects.Mesh;
	
	import flash.events.Event;
	
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.namespaces.delta_internal;
	import net.akimirksnis.delta.game.utils.Utils;
	
	use namespace delta_internal;

	public class CommandExecuter
	{
		// Singleton
		private static var _allowInstantiation:Boolean = false;
		private static var _instance:CommandExecuter = new CommandExecuter(SingletonLock);
		
		private var _lastCommand:String;
		private var _lastResponse:String;
		
		private var core:Core;
		private var renderer:Renderer3D = Renderer3D.instance;
		
		/**
		 * Class constructor.
		 * 
		 * @param lock Singleton lock class.
		 */
		public function CommandExecuter(lock:Class)
		{
			if(lock != SingletonLock)
			{
				throw new Error("The class 'CommandExecutor' is singleton. Use 'CommandExecutor.instance'.");
			}
			
			core = Core.instance;
		}
		
		/*---------------------------
		Command interface
		---------------------------*/			
		
		/**
		 * Executes given console command.
		 * 
		 * @param command String containing command.
		 */
		public function executeCommand(command:String):void
		{
			var subs:Array;
			var parsedInteger:Number;
			
			_lastCommand = command;
			_lastResponse = "";
			
			command = Utils.trim(command);
			
			if(command.length == 0)
			{
				return;				
			}	
			
			// Leave only one whitespace char
			command = command.replace(/\s+/, " ");
			subs = command.split(" ");
			
			if(subs.length == 1)
			{
				executeSingle(subs[0]);
			} else if (subs.length == 2)
			{
				parsedInteger = parseInt(subs[1]);	
				
				if(!isNaN(parsedInteger))
				{		
					executeInteger(subs[0], parsedInteger);
				} else {
					executeString(subs[0], subs[1]);
				}
			}
		}
		
		/*---------------------------
		Execute by type
		---------------------------*/
		
		private function executeInteger(command:String, value:int):void
		{
			var o:Object3D;
			
			// commands not requiring map to be running
			
			if(core.mapRunning)
			{
				switch(command)
				{
					case "show_unit_boundboxes":
					{
						for each(var u:Unit in core.units)
						{
							u.showBoundBox = Boolean(value);
						}
						break;
					}
					case "show_terrain":
					{						
						for each(var m:Mesh in GameMap.currentMap.mapMeshes)
						{
							m.visible = Boolean(value)
						}
						
						break;
					}
					case "show_terrain_wireframe":
					{
						GameMap.currentMap.terrainMeshWireframe.visible = Boolean(value);
						break;
					}
					case "show_colmesh_wireframe":
					{
						GameMap.currentMap.collisionMeshWireframe.visible = Boolean(value);
						break;
					}						
					case "show_generic_wireframe":
					{
						GameMap.currentMap.genericWireframes.visible = Boolean(value);
						break;
					}
					case "show_light_sources":
					{
						renderer.debugLights = Boolean(value);
						break;
					}
					case "light_enable_omni":
					{
						for each(o in GameMap.currentMap.lights)
						{
							if(o is OmniLight)
							{
								o.visible = Boolean(value);
							}
						}
						break;
					}
					case "light_enable_directional":
					{
						for each(o in GameMap.currentMap.lights)
						{
							if(o is DirectionalLight)
							{
								o.visible = Boolean(value);
							}
						}						
						break;
					}
					case "light_enable_spot":
					{
						for each(o in GameMap.currentMap.lights)
						{
							if(o is SpotLight)
							{
								o.visible = Boolean(value);
							}
						}
						break;
					}
					case "light_enable_ambient":
					{
						for each(o in GameMap.currentMap.lights)
						{
							if(o is AmbientLight)
							{
								o.visible = Boolean(value);
							}
						}
						break;
					}
					case "use_camera_mode":
					{
						switch(value)
						{							
							case 1:								
								core.useFPSController();
								break;
							case 2:								
								core.useFreeRoamController();
								break;
						}
						break;
					}
				}
			}
			
			core.dispatchEvent(new Event("command_executed"));
		}
		
		private function executeString(command:String, value:String):void
		{			
			// Commands not requiring map to be running
			
			switch(command)
			{
				case "loadmap":
				{
					core.loader.loadMap(value);
					break;
				}
			}
			
			if(core.mapRunning)
			{
				//
			}
			
			core.dispatchEvent(new Event("command_executed"));
		}
		
		private function executeSingle(command:String):void
		{			
			// commands not requiring map to be running
			
			if(core.mapRunning)
			{
				switch(command)
				{
					case "ping":
						trace("ping");
						break;
				}
			}		
			
			core.dispatchEvent(new Event("command_executed"));
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
				
		/**
		 * Returns class instance.
		 */
		public static function get instance():CommandExecuter
		{			
			return _instance;
		}
		
		/**
		 * Last executed command string.
		 */
		public function get lastCommand():String
		{
			return _lastCommand;
		}
		
		/**
		 * Last response string.
		 */
		public function get lastResponse():String
		{
			return _lastResponse;
		}
	}
}

class SingletonLock {}