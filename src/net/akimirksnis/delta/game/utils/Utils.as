package net.akimirksnis.delta.game.utils
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.TextureResource;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Vector3D;
	import flash.system.Capabilities;

	/**
	 * This class contains frenquently used functions.
	 */
	public class Utils
	{
		public static const HALF_PI:Number = Math.PI / 2;
		
		/**
		 * Converts value in radians to its degree equivalent
		 * 
		 * @param radians Radians.
		 * @return Degrees.
		 */
		public static function radToDeg(radians:Number):Number
		{
			return radians * 180 / Math.PI;
		}
		
		/**
		 * Converts value in degrees to its radian equivalent
		 * 
		 * @param degrees Degrees.
		 * @return Radians.
		 */
		public static function degToRad(degrees:Number):Number
		{
			return degrees * Math.PI / 180;
		}
		
		/**
		 * Generates BitmapTextureResource from regular color
		 * 
		 * @param color Color in hex.
		 * @return TextureResource.
		 */
		public static function texResFromColor(color:uint):TextureResource
		{
			var bd:BitmapData = new BitmapData(512,512, false, color);    
			var bitmap:Bitmap = new Bitmap(bd, "always", true);     
			var texture:BitmapTextureResource = new BitmapTextureResource(bitmap.bitmapData);			
			return texture;
		}
		
		/**
		 * Returns unit vector resulting after finding a vector between two given points and then normalizing it.
		 * 
		 * @string Object3D Object to search in.
		 * @return Unit vector.
		 */
		public static function unitVectorFromPoints(start:Vector3D, end:Vector3D):Vector3D
		{
			var vec:Vector3D = end.subtract(start);
			vec.normalize();
			return vec;
		}
		
		/**
		 * Trims string.
		 * 
		 * @string Object3D Object to search in.
		 * @return Trimmed string.
		 */
		public static function trim(s:String):String
		{
			return s.replace(/^\s+|\s+$/gs, '');
		}
		
		/**
		 * Returns descendant of an object by name.
		 * 
		 * @object Object3D Object to search in.
		 * @name String Target chil name.
		 * @return Found descendant or null.
		 */
		public static function getDescendantByName(object:Object3D, name:String):Object3D
		{
			var current:Object3D;
			
			for(var i:int = 0; i < object.numChildren; i++)
			{
				current = object.getChildAt(i);
				
				if(current.name == name)
				{
					return current;
				} else {
					current = getDescendantByName(current, name);					
					if(current != null)
					{
						return current;
					}
				}
			}
			
			return null;
		}
		
		/**
		 * Returns concatenated bound box of a container and all its children.
		 * 
		 * @container Object3D Object3D with 0 or more children.
		 * @return Concatenated bound box.
		 */
		public static function getConcatenatedBoundBox(container:Object3D):BoundBox
		{
			var currentBoundBox:BoundBox, resultBoundBox:BoundBox;
			var minX:Number = Number.MAX_VALUE, maxX:Number = Number.MIN_VALUE, 
				minY:Number = Number.MAX_VALUE, maxY:Number = Number.MIN_VALUE, 
				minZ:Number = Number.MAX_VALUE, maxZ:Number = Number.MIN_VALUE;
			
			// Recursively search child tree of the container
			for(var i:int = 0; i < container.numChildren; i++)
			{
				currentBoundBox = getConcatenatedBoundBox(container.getChildAt(i));
				
				if(currentBoundBox.minX < minX)
				{
					minX = container.boundBox.minX;
				}
				if(currentBoundBox.minY < minY)
				{
					minY = container.boundBox.minY;
				}
				if(currentBoundBox.minZ < minZ)
				{
					minZ = container.boundBox.minZ;
				}
				if(currentBoundBox.maxX > maxX)
				{
					maxX = container.boundBox.maxX;
				}
				if(currentBoundBox.maxY > maxY)
				{
					maxY = container.boundBox.maxY;
				}
				if(currentBoundBox.maxZ < maxZ)
				{
					maxZ = container.boundBox.maxZ;
				}
			}
			
			// Set found values
			resultBoundBox.minX = minX;
			resultBoundBox.minY = minY;
			resultBoundBox.minZ = minZ;
			resultBoundBox.maxX = maxX;
			resultBoundBox.maxY = maxY;
			resultBoundBox.maxZ = maxZ;
			
			// If there are no children - return container`s own bound box
			if(resultBoundBox == null)
			{
				return container.boundBox;
			}
			
			return resultBoundBox;
		}
	}
}