package com.bit101.components
{
	import com.bit101.components.interfaces.IDataRecipient;	
	import flash.display.DisplayObjectContainer;
	
	public class DataRecipientComponent extends Component implements IDataRecipient
	{
		protected var _dataProvider:Vector.<Object>;
		
		public function DataRecipientComponent(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number = 0)
		{
			super(parent, xpos, ypos);
		}
		
		///////////////////////////////////
		// getter/setters
		///////////////////////////////////
		
		/**
		 * Sets / gets data provider.
		 */
		public function set dataProvider(value:Vector.<Object>):void
		{
			_dataProvider = value;
			invalidate();
		}
		public function get dataProvider():Vector.<Object>
		{
			return _dataProvider;
		}
	}
}