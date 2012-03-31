package net.akimirksnis.delta.game.entities.units
{
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.objects.Mesh;
	
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.weapons.SMG;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	
	public class Walker2 extends Unit
	{		
		/*---------------------------
		Class vars and constants
		---------------------------*/
		
		private static var _count:int = 0;
		private static var _collider:EllipsoidCollider = new EllipsoidCollider(50, 50, 100);
		
		public static const MAX_HEALTH:int = 100;
		public static const SPEED:Number = 800;
		
		/*---------------------------
		Instance vars
		---------------------------*/		
		
		public function Walker2()
		{
			super();
			
			// Increase count on unit creation
			_count++;
			
			/*---------------------------
			Calls to Entity superclass
			---------------------------*/
			
			// Set type of the entity
			_type = EntityType.UNIT_WALKER2;
			
			// Set entity model
			setupModel(Globals.library.getObjectByName(EntityType.UNIT_WALKER2).clone() as Mesh);
			
			// Set unique name
			_namex = type + _count;
			
			// Prepare animations [Unit + Entity]
			setupAnimations();
			
			// Setup event handlers
			setupEventHandlers();
			
			/*---------------------------
			Calls to Unit superclass
			---------------------------*/
			
			// Set basic parameters of this type of entity
			_health = MAX_HEALTH;
			_maxHealth = MAX_HEALTH;
			super._speed = SPEED;
			
			// Set collider
			setupCollider(_collider);
			
			/*---------------------------
			Set weapons available to unit
			Set current weapon
			Handle weapon models
			---------------------------*/
			
			_weapons.push(new SMG(this));
			_currentWeapon = _weapons[_currentWeaponIndex];
			
			for each(var w:Weapon in _weapons)
			{
				Utils.getDescendantByName(this.model, "Base_HumanRPalm").addChild(w.model);
				w.model.visible = false;				
			}
			
			_currentWeapon.model.visible = true;
			
			/*---------------------------
			Other
			---------------------------*/		
		}
		
		/*---------------------------
		Setters/getters
		---------------------------*/
		
		public static function get count():int
		{
			return _count;
		}
		public function get weapon():Weapon
		{
			return _currentWeapon;
		}
		public function get collider():EllipsoidCollider
		{
			return _collider;
		}
		public static function get collider():EllipsoidCollider
		{
			return _collider;
		}
		
		public function set weapon(value:Weapon):void
		{
			_currentWeapon = value;
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