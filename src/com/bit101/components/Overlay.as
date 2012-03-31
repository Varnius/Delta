package com.bit101.components
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	
	public class Overlay extends Component
	{
		protected var _mask:Sprite;
		protected var _background:Sprite;
		protected var _backgroundAlpha:Number = 1.0;
		protected var _backgroundColor:uint = 0x000000;
		protected var _shadow:Boolean = true;
		protected var _gridSize:int = 10;
		protected var _showGrid:Boolean = false;
		protected var _gridColor:uint = 0xd0d0d0;
		protected var _title:String;		
		private var _multiFocusEnabled:Boolean = false;
		
		/**
		 * Container for content added to this panel. This is masked, so best to add children to content, rather than directly to the panel.
		 */
		public var content:Sprite;		
		
		/**
		 * Constructor
		 * @param parent The parent DisplayObjectContainer on which to add this Panel.
		 * @param xpos The x position to place this component.
		 * @param ypos The y position to place this component.
		 */
		public function Overlay(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, title:String = "overlay")
		{
			addEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false, 0, true);
			super(parent, xpos, ypos);	
			_title = title;
		}		
		
		/**
		 * Initializes the component.
		 */
		override protected function init():void
		{
			super.init();
			setSize(100, 100);
		}
		
		/**
		 * Creates and adds the child display objects of this component.
		 */
		override protected function addChildren():void
		{
			_background = new Sprite();
			super.addChild(_background);
			
			_mask = new Sprite();
			_mask.mouseEnabled = false;
			super.addChild(_mask);
			
			content = new Sprite();
			super.addChild(content);
			content.mask = _mask;
			
			//filters = [getShadow(2, true)];
		}		
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		public override function addComponent(child:Component):Component
		{
			super.addComponent(child);
			content.addChild(child);
			return child;
		}
		
		/**
		 * Access to super.addChild
		 */
		public function addRawChild(child:DisplayObject):DisplayObject
		{
			super.addChild(child);
			return child;
		}
		
		/**
		 * Draws the visual ui of the component.
		 */
		override public function draw():void
		{
			// First set w/h according to stage size
			if(stage != null)
			{
				_width = stage.stageWidth;
				_height = stage.stageHeight;
			}
			
			// Then call parent class update size and position of component
			super.draw();
			
			// And finally draw everything
			_background.graphics.clear();
			_background.graphics.beginFill(_backgroundColor, _backgroundAlpha);
			_background.graphics.drawRect(0, 0, _width, _height);
			_background.graphics.endFill();
			
			_mask.graphics.clear();
			_mask.graphics.beginFill(0xFF0000);
			_mask.graphics.drawRect(0, 0, _width, _height);
			_mask.graphics.endFill();
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		protected function moveToTop():void
		{
			parent.setChildIndex(this, parent.numChildren - 1);
		}
		
		/*---------------------------
		Event handlers
		---------------------------*/
		
		protected function onAddedToStage(e:Event):void
		{
			removeEventListener(Event.ADDED_TO_STAGE, onAddedToStage, false);
			draw();
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/		
		
		public function get multiFocusEnabled():Boolean
		{
			return _multiFocusEnabled;
		}		
		public function set multiFocusEnabled(value:Boolean):void
		{
			_multiFocusEnabled = value;
		}
		
		/**
		 * Gets / sets background color of the overlay.
		 */
		public function get backgroundColor():uint
		{
			return _backgroundColor;
		}
		public function set backgroundColor(color:uint):void
		{
			_backgroundColor = color;
			invalidate();
		}		
		
		/**
		 * Gets / sets the alpha of the background of overlay.
		 */
		public function get backgroundAlpha():Number
		{
			return _backgroundAlpha;
		}
		public function set backgroundAlpha(alpha:Number):void
		{
			_backgroundAlpha = alpha;
			invalidate();
		}		
		
		/**
		 * Gets / sets the title of the component.
		 */		
		public function get title():String
		{
			return _title;
		}
		public function set title(title:String):void
		{
			_title = title;
		}
		
		override public function set visible(value:Boolean):void
		{
			// Move overlay to top
			if(value) 
			{
				moveToTop();
			}
			super.visible = value;
		}
	}
}