package net.akimirksnis.delta.game.utils
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.display.Stage3D;
	import flash.utils.getTimer;
	
	import net.akimirksnis.delta.game.gui.GuiController;
	import net.akimirksnis.delta.game.controllers.IsometricController;
	import net.akimirksnis.delta.game.controllers.interfaces.IController;
	import net.akimirksnis.delta.game.core.Core;
	import net.akimirksnis.delta.game.core.Renderer3D;
	import net.akimirksnis.delta.game.core.Library;

	public class Globals
	{
		// Global paths
		public static const LOCAL_ROOT:String = "C:/Users/Varnius/Desktop/delta/data/"
		public static const ASSETS_XML:String = "assets.xml";	
		public static const ANIMATIONS_XML:String = "animations.xml";
		public static const MODEL_DIR:String = "models/";
		public static const ANIMATION_DIR:String = "animations/";
		public static const MATERIAL_DIR_MODELS:String = "materials/models/";
		public static const MATERIAL_DIR_MAPS:String = "materials/maps/";
		public static const SPRITE_DIR:String = "sprites/";
		public static const MAP_DIR:String = "maps/";
		
		// Global gravity
		public static const GRAVITY:Number = 1500;
		
		// Globals that need assigning a value before using
		public static var stage:Stage;
		public static var stage3D:Stage3D;
		public static var gameCore:Core;
		public static var guiController:GuiController;
		public static var GUIRoot:DisplayObjectContainer;
		
		// Global debug mode
		public static const DEBUG_MODE:Boolean = true;
	}
}