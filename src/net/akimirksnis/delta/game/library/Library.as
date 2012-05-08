package net.akimirksnis.delta.game.library
{
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Sprite3D;
	
	import flash.utils.Dictionary;

	public class Library
	{
		private static var _instance:Library = new Library(SingletonLock);	
		
		/*---------------------------
		Objects
		---------------------------*/
		
		private var _meshes:Vector.<Mesh> = new Vector.<Mesh>();
		private var _skins:Vector.<Skin> = new Vector.<Skin>();					
		private var _sprites:Vector.<Sprite3D> = new Vector.<Sprite3D>();		
		private var _objects:Vector.<Object3D> = new Vector.<Object3D>();			
		
		/*---------------------------
		Animations
		---------------------------*/
		
		// Parsed animations for skins (keys - objects from skinVector)
		private var _animations:Dictionary = new Dictionary();		
		
		/*---------------------------
		Misc
		---------------------------*/	
		
		// Object properties parsed from 3DSMax (keys - objects from all object vectors)
		private var _properties:Dictionary = new Dictionary();
		
		// Objects containing various info about each map
		private var _mapData:Array = [];

		/**
		 * Class constructor.
		 */
		public function Library(lock:Class)
		{			
			if(lock != SingletonLock)
			{
				throw new Error("The class 'Library' is singleton. Use 'Library.instance'.");
			}	
		}
		
		/*---------------------------
		Public methods
		---------------------------*/			

		/**
		 * Adds an object to the library.
		 * 
		 * @param object Object to add.
		 */
		public function addObject(object:Object3D):void
		{
			if(object is Mesh)
			{
				_meshes.push(object);
			} else if(object is Skin)
			{
				_skins.push(object);
			} else if(object is Sprite3D)
			{
				_sprites.push(object);
			}			
			
			_objects.push(object);
		}
		
		/**
		 * Gets object3D by name.
		 * 
		 * @param name Object name.
		 * @return Object3D of specified name.
		 */
		public function getObjectByName(name:String):Object3D
		{
			for each(var o:Object3D in _objects)
			{
				if(o.name == name)
					return o;				
			}
			
			return null;
		}	
		
		/**
		 * Gets animation by object name.
		 * 
		 * @param name Object name.
		 * @return AnimationClip instance.
		 */
		public function getAnimationByName(name:String):AnimationClip
		{
			return _animations[getObjectByName(name)];
		}
		
		/**
		 * Gets properties by object name.
		 * 
		 * @param name Object name.
		 * @return Object cotnaining the properties.
		 */
		public function getPropertiesByName(name:String):Object
		{
			return _properties[getObjectByName(name)];
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Returns singleton of this class.
		 */
		public static function get instance():Library
		{			
			return _instance;
		}
		
		/**
		 * List of meshes.
		 */
		public function get meshes():Vector.<Mesh>
		{
			return _meshes;
		}
		
		/**
		 * List of skins.
		 */
		public function get skins():Vector.<Skin>
		{
			return _skins;
		}
		
		/**
		 * List of sprites.
		 */
		public function get sprites():Vector.<Sprite3D>
		{
			return _sprites;
		}
		
		/**
		 * List of all objects ever parsed as assets.
		 */
		public function get objects():Vector.<Object3D>
		{
			return _objects;
		}
		
		/**
		 * Dictionary of animations.
		 */
		public function get animations():Dictionary
		{
			return _animations;
		}
		
		/**
		 * List of properties of models.
		 */
		public function get properties():Dictionary
		{			
			return _properties;
		}
		
		/**
		 * List of objects, each containing info about specific map.
		 */
		public function get mapData():Array
		{
			return _mapData;
		}
	}
}

class SingletonLock {}