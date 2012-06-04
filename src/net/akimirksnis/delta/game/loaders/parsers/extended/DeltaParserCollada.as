package net.akimirksnis.delta.game.loaders.parsers.extended
{
	import alternativa.engine3d.loaders.ParserCollada;
	
	import flash.utils.Dictionary;
	
	public class DeltaParserCollada extends ParserCollada
	{
		private var _xml:XML;
		private var _properties:Dictionary;
		
		/**
		 * @inherit
		 */
		public function DeltaParserCollada()
		{
			super();
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * @inherit
		 */
		public override function parse(data:XML, baseURL:String = null, trimPaths:Boolean = false):void
		{
			_xml = data;
			_properties = new Dictionary();
			super.parse(data, baseURL, trimPaths);			
			parseUserDefinedProperties();
		}
		
		public function getPropertiesByObject(obj:*):Object
		{
			var p:Object;
			
			for each(var o:* in super.objects)
			{
				if(o == obj)
					p = _properties[o];
			}
			
			return p;
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		private function parseUserDefinedProperties():void
		{
			// Fuck this.
			namespace ns = "http://www.collada.org/2005/11/COLLADASchema";
			use namespace ns;
			
			var properties:String;
			
			for each(var o:* in super.objects)
			{
				properties = _xml.library_visual_scenes..visual_scene..node.(@name==o.name).extra.technique.user_properties;
				
				// If not empty/whitespace-filled string
				if(!properties.match(/^\s*$/))
				{								
					// Remove whitespace
					properties = properties.replace(/\s+/g, "");
					
					var container:Object = new Object();
					
					// Fill container object
					for each(var s:String in properties.split(";"))
					{
						var tmp:Array = s.split("=");
						container[tmp[0]] = tmp[1];
					}
					
					// Push container to dictionary
					_properties[o] = container;
				}
			}
		}
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get xml():XML
		{ 
			return _xml; 
		}
		
		public function get properties():Dictionary
		{
			return _properties;
		}
	}
}