package net.akimirksnis.delta.game.entities.weapons
{
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.Box;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	
	import flash.geom.Vector3D;
	
	public class SMG extends InstantDamageWeapon
	{		
		// Class vars and constants
		
		private static var _count:int = 0;
		public static const DAMAGE:int = 10;
		public static const RANGE:int = 500;
		
		// Instance vars
		
		public function SMG(unit:Unit)
		{
			super(unit);
			
			// Increase count on unit creation
			_count++;
			
			/*---------------------------
			Calls to Entity superclass
			---------------------------*/
			
			// Set type of the entity
			_type = EntityType.WEAPON_SMG;			
			// Set entity model
			//_model = Globals.core.getObjectByName(EntityType.UNIT_WALKER2).clone() as Mesh;
			_mesh = new Box(15, 15, 15, 1, 1, 1, false, new FillMaterial(0x00FF00, 0.9));
			Globals.renderer.uploadResources(_mesh.getResources());
			
			// Set unique name
			_name = type + _count;
			
			// Prepare animations [Unit + Entity]
			setupAnimations();
			
			// Setup event handlers
			setupEventHandlers();
			
			// Model selectable?
			mesh.mouseEnabled = false;
			
			/*---------------------------
			Calls to Weapon superclass
			---------------------------*/
			
			// Set basic parameters of this type of entity
			_damage = DAMAGE;
			_range = RANGE;
			// todo - mark thsi point inside max model?
			_fireOriginPoint = new Vector3D(0, 0, 0);
		}
		
		/*---------------------------
		Setters/getters
		---------------------------*/
		
		public static function get count():int
		{
			return _count;
		}
		
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