package net.akimirksnis.delta.game.entities
{
	import alternativa.engine3d.animation.AnimationController;
	import alternativa.engine3d.animation.AnimationSwitcher;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.events.Event3D;
	import alternativa.engine3d.core.events.MouseEvent3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.core.GameCore;
	import net.akimirksnis.delta.game.entities.events.EntityMouseEvent3D;
	
	import flash.events.EventDispatcher;
	import flash.geom.Vector3D;

	public class Entity extends EventDispatcher
	{
		//Properties of an entity
		
		// Model mesh/skin used within the entity
		protected var _model:Mesh;		
		// Entity type
		protected var _type:String = EntityType.ENTITY_UNDEFINED;
		// Entity unique name with unique number at the end, like unit_walker1, unit_walker2 etc
		protected var _namex:String = "default_entity_name";		
		// Debug
		protected var _showBoundBox:Boolean = false;
		protected var _boundBoxWireframe:WireFrame;
		
		//Animation properties
		
		protected var aniController:AnimationController;
		protected var aniSwitcher:AnimationSwitcher;
		protected var currentAnimation:String;
		
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
			
			if(Globals.debugMode)
			{
				var boundBox:BoundBox = this.model.boundBox;
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
				this.model.addChild(_boundBoxWireframe);
			}
		}
		
		protected function setupAnimations():void
		{
			aniController = new AnimationController();
			aniSwitcher = new AnimationSwitcher();
		}
		
		protected function setupEventHandlers():void
		{
			model.addEventListener(MouseEvent3D.CLICK, onSingleClick, false, 0, true);
			model.addEventListener(MouseEvent3D.CLICK, onDoubleClick, false, 0, true);
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		protected function onSingleClick(e:MouseEvent3D):void
		{
			var ev:EntityMouseEvent3D = new EntityMouseEvent3D(e.type, e.bubbles, e.localX, e.localY, e.localZ, e.relatedObject, e.ctrlKey, e.altKey, e.shiftKey, e.buttonDown, e.delta);
			ev.targetEntity = this;
			dispatchEvent(ev);
		}
		
		protected function onDoubleClick(e:MouseEvent3D):void
		{
			var ev:EntityMouseEvent3D = new EntityMouseEvent3D(e.type, e.bubbles, e.localX, e.localY, e.localZ, e.relatedObject, e.ctrlKey, e.altKey, e.shiftKey, e.buttonDown, e.delta);
			ev.targetEntity = this;
			dispatchEvent(ev);
		}
		
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
		
		public function get model():Mesh
		{
			return _model;
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
			return new Vector3D(model.x, model.y, model.z);
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
			// Remove unneeded event lsiteners
			model.removeEventListener(MouseEvent3D.CLICK, onSingleClick, false);
			model.removeEventListener(MouseEvent3D.DOUBLE_CLICK, onDoubleClick, false);
			
			// Nullify model reference
			_model = null;
		}
	}
}