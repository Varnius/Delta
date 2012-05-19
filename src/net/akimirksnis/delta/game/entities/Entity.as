package net.akimirksnis.delta.game.entities
{
	import alternativa.engine3d.animation.AnimationController;
	import alternativa.engine3d.animation.AnimationSwitcher;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.core.Library;
	import net.akimirksnis.delta.game.utils.Globals;

	public class Entity extends EventDispatcher
	{
		//Properties of an entity
		
		// Model mesh/skin used within the entity
		protected var _model:Mesh;
		
		// Geometry used for collisions
		protected var _collisionMesh:Mesh;
		protected var _excludeFromCollisions:Boolean = false;
		protected var _dynamicCollider:Boolean = false;
		
		// Entity type
		protected var _type:String = EntityType.ENTITY_UNDEFINED;
		
		// Entity unique name with unique number at the end, like unit_walker1, unit_walker2 etc
		protected var _namex:String = "default_entity_name";	
		
		//Animation properties		
		protected var aniController:AnimationController;
		protected var aniSwitcher:AnimationSwitcher;
		protected var currentAnimation:String;
		
		protected var library:Library = Library.instance;
		
		// Debug
		protected var _showBoundBox:Boolean = false;
		protected var _boundBoxWireframe:WireFrame;	
		
		public function Entity()
		{
			super();
		}
		
		/*---------------------------
		Setup methods
		(called from child classes)
		---------------------------*/	

		protected function setupModel(model:Mesh):void
		{
			_model = model;
			
			if(Globals.DEBUG_MODE)
			{
				var boundBox:BoundBox = this.m.boundBox;
				var points:Vector.<Vector3D> = new Vector.<Vector3D>();
				points.push(
					new Vector3D(boundBox.minX, boundBox.minY, boundBox.minZ),
					new Vector3D(boundBox.maxX, boundBox.minY, boundBox.minZ),
					new Vector3D(boundBox.maxX, boundBox.maxY, boundBox.minZ),
					new Vector3D(boundBox.minX, boundBox.maxY, boundBox.minZ),
					new Vector3D(boundBox.minX, boundBox.minY, boundBox.minZ),
					new Vector3D(boundBox.minX, boundBox.minY, boundBox.maxZ),
					new Vector3D(boundBox.maxX, boundBox.minY, boundBox.maxZ),
					new Vector3D(boundBox.maxX, boundBox.maxY, boundBox.maxZ),
					new Vector3D(boundBox.minX, boundBox.maxY, boundBox.maxZ),
					new Vector3D(boundBox.minX, boundBox.minY, boundBox.maxZ),
					new Vector3D(boundBox.minX, boundBox.maxY, boundBox.maxZ),
					new Vector3D(boundBox.minX, boundBox.maxY, boundBox.minZ),
					new Vector3D(boundBox.minX, boundBox.maxY, boundBox.maxZ),
					new Vector3D(boundBox.maxX, boundBox.maxY, boundBox.maxZ),
					new Vector3D(boundBox.maxX, boundBox.maxY, boundBox.minZ),
					new Vector3D(boundBox.maxX, boundBox.maxY, boundBox.maxZ),
					new Vector3D(boundBox.maxX, boundBox.minY, boundBox.maxZ),
					new Vector3D(boundBox.maxX, boundBox.minY, boundBox.minZ)
				);
				
				_boundBoxWireframe = WireFrame.createLineStrip(points, 0xFFFFFF, 1, 1);
				_boundBoxWireframe.visible = false;
				Globals.renderer.uploadResources(_boundBoxWireframe.getResources());
				this.m.addChild(_boundBoxWireframe);
			}
		}
		
		protected function setupAnimations():void
		{
			aniController = new AnimationController();
			aniSwitcher = new AnimationSwitcher();
		}
		
		protected function setupEventHandlers():void
		{
			//
		}
		
		/*---------------------------
		Event callbacks
		---------------------------*/
		
		/*---------------------------
		Misc
		---------------------------*/
		
		public override function toString():String
		{
			return _namex;
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get m():Mesh
		{
			return _model;
		}
		
		public function get collisionMesh():Mesh
		{
			return _collisionMesh != null ? _collisionMesh : _model;
		}
		
		public function get excludeFromCollisions():Boolean
		{
			return _excludeFromCollisions;
		}
		
		public function get type():String
		{
			return _type;
		}
		
		public function get name():String
		{
			return _namex;
		}
		
		public function get position():Vector3D
		{
			return new Vector3D(m.x, m.y, m.z);
		}
		
		public function get showBoundBox():Boolean
		{
			return _showBoundBox;
		}
		public function set showBoundBox(value:Boolean):void
		{
			_boundBoxWireframe.visible = value;
			_showBoundBox = value;
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		public function dispose():void
		{			
			// Nullify model reference
			_model = null;
		}

		public function get dynamicCollider():Boolean
		{
			return _dynamicCollider;
		}
	}
}