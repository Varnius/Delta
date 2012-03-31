package net.akimirksnis.delta.game.controllers.interfaces
{
	import alternativa.engine3d.core.Camera3D;

	public interface ICameraController extends IController
	{
		function set camera(camera:Camera3D):void;
		function get camera():Camera3D;
		function think():void;
	}
}