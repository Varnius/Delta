package com.bit101.components
{
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	
	public class StandartListItem extends ListItemBase
	{		
		/**
		 * Constructor
		 * @param parent The parent DisplayObjectContainer on which to add this ListItem.
		 * @param xpos The x position to place this component.
		 * @param ypos The y position to place this component.
		 * @param data The string to display as a label or object with a label property.
		 */
		public function StandartListItem(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0, data:Object = null)
		{
			super(parent, xpos, ypos, data);
		}
		
		///////////////////////////////////
		// public methods
		///////////////////////////////////
		
		/**
		 * Draws the visual ui of the component.
		 */
		public override function draw() : void
		{
			super.draw();
			graphics.clear();
			
			if(_selected)
			{
				graphics.beginFill(_selectedColor);
			}
			else if(_mouseOver)
			{
				graphics.beginFill(_rolloverColor);
			}
			else
			{
				graphics.beginFill(_defaultColor);
			}
			graphics.drawRect(0, 0, width, height);
			graphics.endFill();
			
			if(_data == null) return;
			
			if(_data is String)
			{
				_label.text = _data as String;
			}
			else if(_data.hasOwnProperty("label") && _data.label is String)
			{
				_label.text = _data.label;
			}
			else
			{
				_label.text = _data.toString();
			}
		}		
		
		///////////////////////////////////
		// event handlers
		///////////////////////////////////
		
		///////////////////////////////////
		// getter/setters
		///////////////////////////////////		
	}
}