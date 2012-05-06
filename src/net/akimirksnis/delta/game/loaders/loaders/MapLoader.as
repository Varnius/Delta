package net.akimirksnis.delta.game.loaders.loaders
{
	public class MapLoader extends ModelLoader
	{
		/**
		 * Class constructor.
		 * 
		 * @param modelPath Folder containing models.
		 * @param modelsToLoad A list of models.
		 */
		public function MapLoader(mapsPath:String, mapFilename:String)
		{
			// Load single map file
			super(
				mapsPath,
				XMLList(XML('<model filename="' + mapFilename + '"/>'))
			);
			
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		/**
		 * Loads map.
		 */
		public function loadMap():void
		{			
			super.loadModels();
		}
		
		/*---------------------------
		Event callbacks
		---------------------------*/		
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		public function get loadedMapData():Object
		{			
			super.loadedData[0].mapData = super.loadedData[0].modelData;
			return super.loadedData[0];
		}
	}
}