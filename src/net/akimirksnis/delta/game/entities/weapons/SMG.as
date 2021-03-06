package net.akimirksnis.delta.game.entities.weapons
{
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.primitives.Box;
	
	import flash.geom.Vector3D;
	
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.units.Unit;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	import net.akimirksnis.delta.game.utils.Globals;
	
	public class SMG extends InstantDamageWeapon
	{		
		// Class vars and constants
		
		public static var count:int = 0;
		public static const DAMAGE:int = 10;
		public static const RANGE:int = 500;
		
		// Instance vars
		
		public function SMG(unit:Unit)
		{
			super(unit);
			
			// Increase count on unit creation
			count++;
			
			/*---------------------------
			Calls to Entity superclass
			---------------------------*/
			
			// Set type of the entity
			_type = EntityType.WEAPON_SMG;			
			// Set entity model
			//_model = Globals.core.getObjectByName(EntityType.UNIT_WALKER2).clone() as Mesh;
			
			
			var visual:Box = new Box(15, 15, 15, 1, 1, 1, false, new FillMaterial(0x00FF00, 0.9));
			renderer.uploadResources(visual.getResources());
			setModel(visual);
			
			// Set unique name
			name = type + count;
			
			// Prepare animations [Unit + Entity]
			setupAnimations();
			
			// Setup event handlers
			setupEventHandlers();
			
			// Model selectable?
			_mesh.mouseEnabled = false;
			
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
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		public override function dispose():void
		{			
			super.dispose();
			count--;
		}
	}
}