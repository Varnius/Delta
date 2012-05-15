package net.akimirksnis.delta.game.core
{	
	import alternativa.engine3d.core.*;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.lights.*;
	import alternativa.engine3d.objects.Sprite3D;
	
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import net.akimirksnis.delta.game.debug.LightDebugSprite;
	import net.akimirksnis.delta.game.utils.Globals;

	/**
	* Renderer3D class. Acts as an interface between stage3D and game logic.
	*/
	public class Renderer3D extends EventDispatcher
	{
		private static var _allowInstantiation:Boolean = false;
		private static var _instance:Renderer3D = new Renderer3D(SingletonLock); 
		
		private var library:Library = Library.instance;
		
		// Current camera
		private var _camera:Camera3D;
		// Reference to the stage
		private var stage:Stage;		
		// Reference to stage3D
		public var stage3D:Stage3D;		
		// This will have all other 3D objects attached
		private var _mainContainer:Object3D;
		// Mark lights
		private var _markLights:Boolean = false;
		
		/**
		 * Creates new instance of this class.
		 * 
		 * @param stage3D reference to stage3D
		 * @param cameraMode reference to CameraMode object of needed type
		 * @return New instance of this class.
		 */
		public function Renderer3D(lock:Class)
		{
			if(lock != SingletonLock)
			{
				throw new Error("The class 'Renderer3D' is singleton. Use 'Core.instance'.");
			}
			
			stage = Globals.stage;
			this.stage3D = Globals.stage3D;
			
			// Create main container
			_mainContainer = new Object3D();	
			_mainContainer.name = "main_container";
			
			// On stage resize
			stage.addEventListener(Event.RESIZE, onStageResize);
		}
		
		/**
		 * Adds new Object3D to the main container
		 * 
		 * @param objectD Object to add.
		 * @param uploadResources Uploads resources that belong to the object if set to true.
		 */
		public function addObject3D(object:Object3D, uploadResources:Boolean = false):Object3D
		{
			_mainContainer.addChild(object);
			
			if(uploadResources)
			{
				// Upload resources that belong to this object and its children			
				for each(var resource:Resource in object.getResources(true))
				{
					resource.upload(stage3D.context3D);
				}
			}
			
			return object;
		}
		
		/**
		 * Removes Object3D from the main container
		 * 
		 * @param object3D Object to remove.
		 * @param disposeResources Disposes of the resources that belong to this object and its children if set to true.
		 */
		public function removeObject3D(object:Object3D, disposeResources:Boolean = false):Object3D
		{
			_mainContainer.removeChild(object);
			
			if(disposeResources)
			{
				// Dispose of resources that belong to this object and its children
				for each(var resource:Resource in object.getResources(true))
				{
					resource.dispose()
				}
			}
			
			return object;
		}
		
		/**
		 * Uploads resources to VGA.
		 * 
		 * @param resources Resources to upload.
		 */
		public function uploadResources(resources:Vector.<Resource>):void
		{
			for each(var resource:Resource in resources)
			{
				resource.upload(stage3D.context3D);
			}
		}
		
		/**
		 * Uploads single resource to VGA.
		 * 
		 * @param resource Resource to upload.
		 */
		public function uploadResource(resource:Resource):void
		{
			resource.upload(stage3D.context3D);
		}
		
		/**
		 * Disposes multiple resources.
		 * 
		 * @param resource Resources to dispose.
		 */
		public function disposeResources(resources:Vector.<Resource>):void
		{
			for each(var resource:Resource in resources)
			{
				resource.dispose();
			}
		}
		
		/**
		 * Attaches all lights, passed in vector.
		 * 
		 * @param lights Vector containing lights to attach.
		 * @param skipAmbient Indicates whether skip ambient lights.
		 */
		public function addLights(lights:Vector.<Light3D>, skipAmbient:Boolean = true):void
		{
			for each(var l:Light3D in lights)
			{
				if(skipAmbient && (l is AmbientLight))
				{
					continue;
				} else {
					addObject3D(l);
				}
			}
		}
		
		/**
		 * Attach single light.
		 * 
		 * @param light Light to attach.
		 */
		public function addLight(light:Light3D):void
		{
			addObject3D(light);
		}
		
		/**
		 * Removes single light.
		 * 
		 * @param light Light to remove.
		 */
		public function removeLight(light:Light3D):void
		{
			removeObject3D(light);
		}
		
		/**
		 * Renders one frame.
		 * Updates camera and camera controller.
		 */
		public function renderFrame():void
		{			
			// Render
			_camera.render(stage3D);
		}
		
		/*---------------------------
		Debug methods
		---------------------------*/
		
		/**
		 * Get lights debug state.
		 * Debug method.
		 */
		public function get debugLights():Boolean
		{
			return _markLights;
		}
		
		/**
		 * Marks each light that is not AmbientLight with Sprite3D icons, makes the lights switchable
		 * Debug method.
		 */
		public function set debugLights(mark:Boolean):void
		{
			var l:Light3D;
			var sprite:LightDebugSprite;
			
			if(mark && !_markLights)
			{
				_markLights = true;
				
				// Add markers for different light types
				for each(l in GameMap.currentMap.lights)
				{
					if(l is DirectionalLight)
					{
						//sprite = library.getObjectByName("sprite_directionallight").clone();
						sprite = new LightDebugSprite(library.getObjectByName("sprite_directionallight") as Sprite3D);
						l.parent.addChild(sprite);
						sprite.x = l.x;
						sprite.y = l.y;
						sprite.z = l.z;
						sprite.parentLight = l;
					}
					
					if(l is OmniLight)
					{
						sprite = new LightDebugSprite(library.getObjectByName("sprite_omnilight") as Sprite3D);
						l.parent.addChild(sprite);
						sprite.x = l.x;
						sprite.y = l.y;
						sprite.z = l.z;
						sprite.parentLight = l;
					}
					
					if(l is SpotLight)
					{
						sprite = new LightDebugSprite(library.getObjectByName("sprite_spotlight") as Sprite3D);
						l.parent.addChild(sprite);
						sprite.x = l.x;
						sprite.y = l.y;
						sprite.z = l.z;
						sprite.parentLight = l;
					}					
					
					// Add switch listeners
					if(!(l is AmbientLight))
					{
						sprite.addEventListener(MouseEvent3D.CLICK, onLightClick, false, 0, true);
						sprite.useHandCursor = true;
					}
				}
			} 
			
			if(!mark && _markLights)
			{
				_markLights = false;
				
				// Remove markers for different light types
				for each(l in GameMap.currentMap.lights)
				{
					if(l is DirectionalLight)
					{
						sprite = l.parent.getChildByName("sprite_directionallight") as LightDebugSprite;
						l.parent.removeChild(sprite);
					}
					
					if(l is OmniLight)
					{
						sprite = l.parent.getChildByName("sprite_omnilight") as LightDebugSprite;
						l.parent.removeChild(sprite);
					}
					
					if(l is SpotLight)
					{
						sprite = l.parent.getChildByName("sprite_spotlight") as LightDebugSprite;
						l.parent.removeChild(sprite);
					}
					
					// Remove switch listeners
					if(!(l is AmbientLight))
					{
						sprite.removeEventListener(MouseEvent3D.CLICK, onLightClick, false);
					}
				}
			}
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		private function onLightClick(e:Event):void
		{
			var la:Light3D = (e.target as LightDebugSprite).parentLight;
			
			if(!la.visible)
			{
				la.visible = true;
				trace('[Renderer3D] Light enabled.');
			} else {
				la.visible = false;
				trace('[Renderer3D] Light disabled.');
			}
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		protected function onStageResize(e:Event):void
		{
			if(_camera != null)
			{
				// Resize view on stage resize
				_camera.view.width = stage.stageWidth;
				_camera.view.height = stage.stageHeight;
			}			
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Class instance.
		 */
		public static function get instance():Renderer3D
		{			
			return _instance;
		}
		
		/**
		 * Camera mode used for rendering.
		 */
		public function get camera():Camera3D
		{
			return _camera;
		}
		
		/**
		 * @private
		 */
		public function set camera(camera:Camera3D):void
		{
			if(_camera != null)
			{
				// Remove view and diagram
				stage.removeChild(_camera.view);
				stage.removeChild(_camera.diagram);
				
				// Remove camera itself
				//_mainContainer.removeChild(_camera);
			}			
			_camera = camera;
			
			// Attach camera to the main containers
			//_mainContainer.addChild(_camera);
			
			// Attach camera output to the stage
			stage.addChild(_camera.view);
			stage.addChild(_camera.diagram);
			
			// Resize stage if necessary
			onStageResize(null);
		}
		
		/**
		 * Main container with all other objects in the scene attached. Root of object3D hierarchy tree.
		 */
		public function get mainContainer():Object3D
		{
			return _mainContainer;
		}
	}
}

class SingletonLock {}