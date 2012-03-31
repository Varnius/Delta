package net.akimirksnis.delta.game.entities.events
{
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.core.events.MouseEvent3D;
	
	import net.akimirksnis.delta.game.entities.Entity;
	
	import flash.events.Event;
	
	public class EntityMouseEvent3D extends MouseEvent3D
	{
		private var _targetEntity:Entity;
		
		public function get targetEntity():Entity {return _targetEntity;}
		public function set targetEntity(t:Entity):void {_targetEntity = t;}
		
		public function EntityMouseEvent3D(type:String, bubbles:Boolean=true, localX:Number=NaN, localY:Number=NaN, localZ:Number=NaN, relatedObject:Object3D=null, ctrlKey:Boolean=false, altKey:Boolean=false, shiftKey:Boolean=false, buttonDown:Boolean=false, delta:int=0, targetEntity:Entity=null)
		{
			super(type, bubbles, localX, localY, localZ, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta);
			_targetEntity = targetEntity;
		}
		
		public override function clone():Event
		{
			return new EntityMouseEvent3D(type, bubbles, localX, localY, localZ, relatedObject, ctrlKey, altKey, shiftKey, buttonDown, delta, targetEntity);
		}
	}
}