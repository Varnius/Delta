package net.akimirksnis.delta.game.loaders.parsers.extended
{
	import alternativa.engine3d.loaders.ParserA3D;
	import alternativa.engine3d.loaders.ParserMaterial;
	import alternativa.engine3d.resources.ExternalTextureResource;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	public class DeltaParserA3D extends ParserA3D
	{
		private var pathApplied:Dictionary = new Dictionary();
		
		public function DeltaParserA3D()
		{
			super();
		}
		
		public function parse2(input:ByteArray, materialsPath:String = ""):void
		{
			super.parse(input);
			
			// Append materials path
			for each(var m:ParserMaterial in super.materials)
			{
				for each(var o:Object in m.textures)
				{
					if(o is ExternalTextureResource && !pathApplied[o])
					{
						ExternalTextureResource(o).url = materialsPath + ExternalTextureResource(o).url;
						pathApplied[o] = true;
					}
				}
			}
		}
	}
}