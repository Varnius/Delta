package net.akimirksnis.delta.game.entities
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.core.Library;
	import net.akimirksnis.delta.game.core.Renderer3D;
	import net.akimirksnis.delta.game.utils.Globals;

	public class Entity extends Object3D
	{		
		protected var _type:String = EntityType.ENTITY_UNDEFINED;	
		protected var library:Library = Library.instance;	
		protected var renderer:Renderer3D = Renderer3D.instance;
		
		// Geometry
		protected var _mesh:Mesh;
		protected var _collisionMesh:Mesh;
		protected var _excludeFromCollisions:Boolean = false;
		
		// Debug
		protected var _showBoundBox:Boolean = false;
		protected var _boundBoxWireframe:WireFrame;	
		
		/**
		 * Class constructor.
		 */
		public function Entity()
		{
			super();
		}
		
		/*---------------------------
		Public methods
		---------------------------*/	
		
		/**
		 * @inherit
		 */
		public override function calculateBoundBox():void
		{
			super.calculateBoundBox();
			boundBox = _mesh.boundBox;			
		}
		
		/*---------------------------
		Setup helpers
		---------------------------*/	

		/**
		 * Sets model for this entity.
		 * 
		 * @param model Source mesh.
		 */
		protected function setModel(model:Mesh):void
		{
			addChild(model);
			_mesh = model;
			calculateBoundBox();
			
			if(Globals.DEBUG_MODE)
			{
				var boundBox:BoundBox = this.boundBox;
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
				renderer.uploadResources(_boundBoxWireframe.getResources());
				addChild(_boundBoxWireframe);
			}
		}	
		
		/**
		 * Sets up event handlers.
		 */
		protected function setupEventHandlers():void
		{
			// ..
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/**
		 * Entity type.
		 */
		public function get type():String
		{
			return _type;
		}
		
		/**
		 * Indicates whether this entity should be excluded from collision routines.
		 */
		public function get excludeFromCollisions():Boolean
		{
			return _excludeFromCollisions;
		}
		
		/**
		 * Collision mesh.
		 */
		public function get collisionMesh():Object3D
		{
			return _collisionMesh != null ? _collisionMesh : _mesh;
		}
		
		/**
		 * Entity bound box visibility.
		 */
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
		
		/**
		 * Disposes an entity.
		 */
		public function dispose():void
		{
			// ..
		}	
	}
}