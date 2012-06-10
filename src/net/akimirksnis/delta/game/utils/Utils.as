package net.akimirksnis.delta.game.utils
{
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.core.Light3D;
	import alternativa.engine3d.core.Object3D;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.Skin;
	import alternativa.engine3d.objects.Sprite3D;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.resources.BitmapTextureResource;
	import alternativa.engine3d.resources.TextureResource;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.core.GameMap;

	/**
	 * This class contains some frequently used generic stuff.
	 */
	public class Utils
	{
		public static const HALF_PI:Number = Math.PI / 2;
		public static const UP_VECTOR:Vector3D = new Vector3D(0, 0, 1);
		public static const DOWN_VECTOR:Vector3D = new Vector3D(0, 0, -1);		
		public static const ZERO_VECTOR:Vector3D = new Vector3D(0, 0, 0);
		
		/*---------------------------
		Method: getColoredHierarchyAsHTMLString
		---------------------------*/
		
		public static const COLOR_DEFAULT:String = "#D1D1D1";
		public static const COLOR_GAMEMAP:String = "#EFEFEF";
		public static const COLOR_MESH:String = "#8AFF00";
		public static const COLOR_SKIN:String = "#9000FF";
		public static const COLOR_LIGHT3D:String = "#FFDE00";
		public static const COLOR_SPRITE3D:String = "#009AC6";
		public static const COLOR_WIREFRAME:String = "#FF84E6";
		
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
			var bd:BitmapData = new BitmapData(64, 64, false, color);    
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
		 * @string Input string.
		 * @return Trimmed string.
		 */
		public static function trim(s:String):String
		{
			return s.replace(/^\s+|\s+$/gs, '');
		}
		
		/**
		 * Trims file extension in given string. (format: ****.***)
		 * 
		 * @string Input string.
		 * @return Trimmed string.
		 */
		public static function trimExtension(s:String):String
		{
			return s.match(/(.*)\.(.*)/)[1];
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
		 * Check if one Object3D is a descendant of another Object3D.
		 * 
		 * @object Object3D Parent object.
		 * @object2 Possible descendant.
		 * @return True if second object is descendant of the first one or first one itself.
		 */
		public static function isDescendantOf(object:Object3D, object2:Object3D):Boolean
		{
			var result:Boolean = false;
			var current:Object3D;
			
			if(object == object2)
			{
				return true;
			}
			
			for(var i:int = 0; i < object.numChildren; i++)
			{
				current = object.getChildAt(i);
				
				if(current == object2)
				{
					return true;
				} else {
					if(isDescendantOf(current, object2))
					{
						return true;
					}
				}
			}
			
			return result;
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
			var hasValidChildren:Boolean = false;
			var minX:Number = Number.MAX_VALUE, maxX:Number = Number.MIN_VALUE, 
				minY:Number = Number.MAX_VALUE, maxY:Number = Number.MIN_VALUE, 
				minZ:Number = Number.MAX_VALUE, maxZ:Number = Number.MIN_VALUE;
			
			if(container.numChildren == 0)
			{
				return container.boundBox;
			}
			
			// Recursively search child tree of the container
			for(var i:int = 0; i < container.numChildren; i++)
			{
				currentBoundBox = getConcatenatedBoundBox(container.getChildAt(i));
				
				if(currentBoundBox == null)
				{
					continue;
				}
				
				hasValidChildren = true;
				
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
				if(currentBoundBox.maxZ > maxZ)
				{
					maxZ = container.boundBox.maxZ;
				}
			}
			
			if(!hasValidChildren)
			{
				return container.boundBox;
			}
			
			resultBoundBox = new BoundBox();
			
			// Set found values
			resultBoundBox.minX = minX;
			resultBoundBox.minY = minY;
			resultBoundBox.minZ = minZ;
			resultBoundBox.maxX = maxX;
			resultBoundBox.maxY = maxY;
			resultBoundBox.maxZ = maxZ;
			
			return resultBoundBox;
		}
		
		/**
		 * Generates wireframe from passed mesh (including its children).
		 * 
		 * @param mesh Source mesh.
		 * @param color Color of the wireframe.
		 * @return Generated wireframe.
		 */
		public static function generateWireframeWithChildren(mesh:Mesh, color:uint):WireFrame
		{
			var wf:WireFrame;
			var child:Object3D;
			
			wf = WireFrame.createEdges(mesh, color);
			wf.name = "wireframe-" + mesh.name;
			
			for(var i:int = 0; i < mesh.numChildren; i++)
			{
				child = mesh.getChildAt(i);
				
				if(child is Mesh)
				{
					wf.addChild(generateWireframeWithChildren(child as Mesh, color));
				}				
			}
			
			return wf;
		}		
		
		/**
		 * Returns a hierarchy for given object.
		 * 
		 * @param object Source object. 
		 */
		public static function getColoredHierarchyAsHTMLString(object:Object3D, spacer:String = ""):String
		{
			var result:String = "";
			var color:String = COLOR_DEFAULT;
			
			if(object is Skin)
			{
				color = COLOR_SKIN;
			} else if(object is Mesh) {
				color = COLOR_MESH;
			} else if(object is Light3D) {
				color = COLOR_LIGHT3D;
			} else if(object is GameMap) {
				color = COLOR_GAMEMAP;
			} else if(object is Sprite3D) {
				color = COLOR_SPRITE3D;
			} else if(object is Mesh) {
				color = COLOR_MESH;
			} else if(object is WireFrame) {
				color = COLOR_WIREFRAME;
			}
			
			result += spacer + "<font color='" + color + "'>" + object + "</font>" + "\n";
			
			for(var i:int = 0; i < object.numChildren; i++)
			{
				result += getColoredHierarchyAsHTMLString(object.getChildAt(i), spacer + "     ");
			}
			
			return result;
		}
		
		/**
		 * Returns hierarchy of Object3Ds as a vector.
		 * 
		 * @param root Hierarchy root object.
		 * @return Hierarchy vector representation.
		 */
		public static function getFlattenedMeshHierachy(root:Object3D):Vector.<Mesh>
		{
			var result:Vector.<Mesh> = new Vector.<Mesh>();
			
			// Add root object if it is a mesh
			if(root is Mesh)
			{
				result.push(root);
			}
			
			// Loop through children and collect meshes
			for(var i:int = 0; i < root.numChildren; i++)
			{
				result = result.concat(getFlattenedMeshHierachy(root.getChildAt(i)));
			}
			
			// Quickly drop duplicates
			/*var set:Object = {};
			
			for(i = 0; i < result.length; i++)
			{
				set[result[i]] = true;
			}
			
			result = new Vector.<Mesh>();
			
			for(var prop:* in set)
			{
				result.push[prop];
			}*/
			
			return result;
		}
	}
}