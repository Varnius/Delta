package net.akimirksnis.delta.game.gui.components
{
	import com.bit101.components.ListItemBase;
	
	import flash.display.DisplayObjectContainer;
	
	public class LevelListItem extends ListItemBase
	{
		public function LevelListItem(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0, data:Object = null)
		{
			super(parent, xpos, ypos, data);			
		}
		
		///////////////////////////////////
		// public methods
		///////////////////////////////////
		
		/**
		 * Draws the visual ui of the component.
		 */
		public override function draw():void
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

			if(_data != null)
			{
				_label.text = _data.name;
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