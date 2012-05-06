package net.akimirksnis.delta.game.library
{
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Sprite3D;
	
	import flash.utils.Dictionary;
	
	import net.akimirksnis.delta.game.core.GameMap;

	public class Library
	{
		private static var _allowInstantiation:Boolean = false;
		private static var _instance:Library;	
		
		/*---------------------------
		Objects
		---------------------------*/
		
		private var _meshes:Vector.<Mesh> = new Vector.<Mesh>();
		private var _skins:Vector.<Skin> = new Vector.<Skin>();
		private var _lights:Vector.<Light3D> = new Vector.<Light3D>();				
		private var _sprites:Vector.<Sprite3D> = new Vector.<Sprite3D>();		
		private var _objects:Vector.<Object3D> = new Vector.<Object3D>();
		private var _mapMeshes:Vector.<Mesh> = new Vector.<Mesh>();		
		private var _mapObjects:Vector.<Object3D> = new Vector.<Object3D>();		
		
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
		
		// Properties of map objects
		private var _mapProperties:Dictionary = new Dictionary();
		
		// Objects containing various info about each map
		private var _mapData:Array = [];
		
		/*---------------------------
		Map
		---------------------------*/
		
		private var _map:GameMap;
		
		/**
		 * Class constructor.
		 */
		public function Library()
		{
			if(!_allowInstantiation)
				throw new Error("The class 'Library' is singleton.");
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
			} else if(object is Light3D)
			{
				_lights.push(object);	
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
		 * Gets map object3D by name.
		 * 
		 * @param name Object name.
		 * @return Object3D of specified name.
		 */
		public function getMapObjectByName(name:String):Object3D
		{
			for each(var o:Object3D in _mapObjects)
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
			if(_instance == null)
			{
				_allowInstantiation = true;
				_instance = new Library();
				_allowInstantiation = false;
			}
			
			return _instance;
		}
		
		public function get meshes():Vector.<Mesh>
		{
			return _meshes;
		}
		
		public function get skins():Vector.<Skin>
		{
			return _skins;
		}
		
		public function get lights():Vector.<Light3D>
		{
			return _lights;
		}
		
		public function get sprites():Vector.<Sprite3D>
		{
			return _sprites;
		}
		
		public function get objects():Vector.<Object3D>
		{
			return _objects;
		}
		
		public function get mapMeshes():Vector.<Mesh>
		{
			return _mapMeshes;
		}
		
		public function get mapObjects():Vector.<Object3D>
		{
			return _mapObjects;
		}
		
		public function get animations():Dictionary
		{
			return _animations;
		}
		
		public function get properties():Dictionary
		{
			
			return _properties;
		}
		
		/**
		 * Map object property dictionary.
		 */
		public function get mapProperties():Dictionary
		{
			return _mapProperties;
		}
		public function set mapProperties(value:Dictionary):void
		{
			_mapProperties = value;
		}
		
		public function get mapData():Array
		{
			return _mapData;
		}
		
		/**
		 * Current map.
		 */
		public function get map():GameMap
		{
			return _map;
		}		
		public function set map(value:GameMap):void
		{
			_map = value;
		}
	}
}