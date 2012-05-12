/**
 * Component.as
 * Keith Peters
 * version 0.9.10
 * 
 * Base class for all components
 * 
 * Copyright (c) 2011 Keith Peters
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 * 
 * 
 * 
 * Components with text make use of the font PF Ronda Seven by Yuusuke Kamiyamane
 * This is a free font obtained from http://www.dafont.com/pf-ronda-seven.font
 */
 
package com.bit101.components
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.filters.DropShadowFilter;

	[Event(name="resize", type="flash.events.Event")]
	[Event(name="draw", type="flash.events.Event")]
	public class Component extends Sprite
	{
		// NOTE: Flex 4 introduces DefineFont4, which is used by default and does not work in native text fields.
		// Use the embedAsCFF="false" param to switch back to DefineFont4. In earlier Flex 4 SDKs this was cff="false".
		// So if you are using the Flex 3.x sdk compiler, switch the embed statment below to expose the correct version.
		
		// Flex 4.x sdk:
		[Embed(source="/assets/orbitron-light.otf", embedAsCFF="false", fontName="Orbitron Light", mimeType="application/x-font")]
		protected var Orbitron:Class;
		
		protected var _width:Number = 0;
		protected var _height:Number = 0;
		protected var _tag:int = -1;
		protected var _enabled:Boolean = true;
		
		//Reference to the component parent of this component
		protected var _componentParent:Component;
		protected var _childComponents:Vector.<Component> = new Vector.<Component>();
		
		// Margins
		protected var _top:Number;		
		protected var _right:Number;		
		protected var _bottom:Number;
		protected var _left:Number;
		
		// Align
		protected var _hAlign:String = "none";
		protected var _vAlign:String = "none";
		
		public static const DRAW:String = "draw";
		
		/**
		 * Constructor
		 * @param parent The parent DisplayObjectContainer on which to add this component.
		 * @param xpos The x position to place this component.
		 * @param ypos The y position to place this component.
		 */
		public function Component(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0)
		{			
			move(xpos, ypos);
			init();
			if(parent != null)
			{
				parent.addChild(this);
			}
		}
		
		/**
		 * Initilizes the component.
		 */
		protected function init():void
		{
			addChildren();
			invalidate();
		}
		
		/**
		 * Overriden in subclasses to create child display objects.
		 */
		protected function addChildren():void
		{
			// ...
		}
		
		public function addComponent(child:Component):Component
		{
			_childComponents.push(child);
			child.componentParent = this;
			return child;
		}
		
		/**
		 * DropShadowFilter factory method, used in many of the components.
		 * @param dist The distance of the shadow.
		 * @param knockout Whether or not to create a knocked out shadow.
		 */
		protected function getShadow(dist:Number, knockout:Boolean = false):DropShadowFilter
		{
			return new DropShadowFilter(dist, 45, Style.DROPSHADOW, 1, dist, dist, .3, 1, knockout);
		}
		
		/**
		 * Marks the component to be redrawn on the next frame.
		 */
		protected function invalidate():void
		{
			addEventListener(Event.ENTER_FRAME, onInvalidate);
		}
		
		/**
		 * Updates component size according to such user defined params as
		 * top, right, bottom, left, horizontalAlign, verticalAlign.
		 */
		protected function updateSizingAndPosition():void
		{
			if(_componentParent == null)
			{	
				return;
			}
			
			//---------------------
			// Horizontal margins
			//---------------------
			
			// If both set
			if(!isNaN(_left) && !isNaN(_right))
			{
				x = _left;
				_width = _componentParent.width - _left - _right;
			} else {
				
				// If only one set
				if(!isNaN(_left))
				{
					x = _left;
				}
				if(!isNaN(_right))
				{
					x = _componentParent.width - _width - _right;
				}
			}
			
			// Horizontal align
			switch(_hAlign)
			{
				case "left":
				{
					x = 0;
					break;
				}
				case "center":
				{
					x = Math.round((_componentParent.width - _width) / 2);
					break;
				}
				case "right":
				{
					x = _componentParent.width - _width;
					break;
				}
			}
			
			//---------------------
			// Vertical margins
			//---------------------
			
			// If both set
			if(!isNaN(_top) && !isNaN(_bottom))
			{
				y = _top;
				_height = _componentParent.height - _top - _bottom;
			} else {
				
				// If only one set
				if(!isNaN(_top))
				{
					y = _top;						
				}
				if(!isNaN(_bottom))
				{
					y = _componentParent.height - _height - _bottom;
				}
			}
			
			// Vertical align
			switch(_vAlign)
			{
				case "top":
				{
					y = 0;
					break;
				}
				case "middle":
				{
					y = Math.round((_componentParent.height - _height) / 2);
					break;
				}
				case "bottom":
				{
					y = _componentParent.height - _height;
					break;
				}
			}
		}
		
		///////////////////////////////////
		// public methods
		///////////////////////////////////
		
		/**
		 * Moves the component to the specified position.
		 * @param xpos the x position to move the component
		 * @param ypos the y position to move the component
		 */
		public function move(xpos:Number, ypos:Number):void
		{
			x = Math.round(xpos);
			y = Math.round(ypos);
		}
		
		/**
		 * Sets the size of the component.
		 * @param w The width of the component.
		 * @param h The height of the component.
		 */
		public function setSize(width:Number, height:Number):void
		{
			_width = width;
			_height = height;
			dispatchEvent(new Event(Event.RESIZE));
			invalidate();
		}
		
		/**
		 * Abstract draw function.
		 */
		public function draw():void
		{
			updateSizingAndPosition();
			
			// Redraw child components
			for each(var c:Component in _childComponents)
			{
				c.draw();
			}
			
			dispatchEvent(new Event(Component.DRAW));
			//trace("drawing: "+this);
		}
		
		///////////////////////////////////
		// event handlers
		///////////////////////////////////
		
		/**
		 * Called one frame after invalidate is called.
		 */
		protected function onInvalidate(event:Event):void
		{
			removeEventListener(Event.ENTER_FRAME, onInvalidate);
			draw();
		}
		
		///////////////////////////////////
		// getter/setters
		///////////////////////////////////
		
		/**
		 * Sets/gets x coordinate of the component
		 */
		public override function set x(value:Number):void
		{
			super.x = Math.round(value);			
		}
		
		/**
		 * Sets/gets y coordinate of the component
		 */
		public override function set y(value:Number):void
		{
			super.y = Math.round(value);			
		}
		
		/**
		 * Sets/gets top margin of the component
		 */
		public function set top(value:Number):void
		{
			_top = Math.round(value);			
		}
		public function get top():Number
		{
			return _top;
		}
		
		/**
		 * Sets/gets right margin of the component
		 */
		public function set right(value:Number):void
		{
			_right = Math.round(value);
		}
		public function get right():Number
		{
			return _right;
		}
		
		/**
		 * Sets/gets bottom margin of the component
		 */
		public function set bottom(value:Number):void
		{
			_bottom = Math.round(value);
		}
		public function get bottom():Number
		{
			return _bottom;
		}
		
		/**
		 * Sets/gets left margin of the component
		 */
		public function set left(value:Number):void
		{
			_left = Math.round(value);
		}
		public function get left():Number
		{
			return _left;
		}
		
		/**
		 * Sets/gets horizontal align of the component
		 */
		public function set horizontalAlign(value:String):void
		{
			_hAlign = value;
		}
		public function get horizontalAlign():String
		{
			return _hAlign;
		}
		
		/**
		 * Sets/gets vertical align of the component
		 */
		public function set verticalAlign(value:String):void
		{
			_vAlign = value;
		}
		public function get verticalAlign():String
		{
			return _vAlign;
		}
		
		/**
		 * Sets/gets the width of the component.
		 */
		override public function set width(w:Number):void
		{
			_width = w;
			invalidate();
			dispatchEvent(new Event(Event.RESIZE));
		}
		override public function get width():Number
		{
			return _width;
		}
		
		/**
		 * Sets/gets the height of the component.
		 */
		override public function set height(h:Number):void
		{
			_height = h;
			invalidate();
			dispatchEvent(new Event(Event.RESIZE));
		}
		override public function get height():Number
		{
			return _height;
		}
		
		/**
		 * Sets/gets in integer that can identify the component.
		 */
		public function set tag(value:int):void
		{
			_tag = value;
		}
		public function get tag():int
		{
			return _tag;
		}

		/**
		 * Sets/gets whether this component is enabled or not.
		 */
		public function set enabled(value:Boolean):void
		{
			_enabled = value;
			mouseEnabled = mouseChildren = _enabled;
            tabEnabled = value;
			alpha = _enabled ? 1.0 : 0.5;
		}
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		/**
		 * Sets/gets this component`s true parent.
		 */
		public function set componentParent(value:Component):void
		{
			_componentParent = value;
		}
		public function get componentParent():Component
		{
			return _componentParent;
		}
	}
}