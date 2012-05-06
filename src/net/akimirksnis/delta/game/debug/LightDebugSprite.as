package net.akimirksnis.delta.game.debug
{
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.objects.Sprite3D;

	public class LightDebugSprite extends Sprite3D
	{
		public var parentLight:Light3D;
		
		public function LightDebugSprite(sprite:Sprite3D)
		{
			super(sprite.width, sprite.height, sprite.material);
			clonePropertiesFrom(sprite);
		}
	}
}