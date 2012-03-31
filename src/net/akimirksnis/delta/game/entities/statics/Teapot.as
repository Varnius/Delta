package net.akimirksnis.delta.game.entities.statics
{
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.objects.Mesh;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.weapons.SMG;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	
	public class Teapot extends Entity
	{		
		/*---------------------------
		Class vars and constants
		---------------------------*/
		
		private static var _count:int = 0;
		
		/*---------------------------
		Instance vars
		---------------------------*/		
		
		public function Teapot()
		{
			super();
			
			// Increase count on unit creation
			_count++;
			
			/*---------------------------
			Calls to Entity superclass
			---------------------------*/
			
			// Set type of the entity
			_type = EntityType.STATIC_TEAPOT;
			
			// Set entity model
			setupModel(Globals.library.getObjectByName(EntityType.STATIC_TEAPOT).clone() as Mesh);
			
			// Set unique name
			_namex = type + _count;
			
			// Prepare animations [Unit + Entity]
			setupAnimations();
			
			// Setup event handlers
			//setupEventHandlers();
			
			/*---------------------------
			Other
			---------------------------*/		
		}
		
		/*---------------------------
		Setters/getters
		---------------------------*/
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		public override function dispose():void
		{
			_count--;
			super.dispose();
		}
	}
}