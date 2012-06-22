package net.akimirksnis.delta.game.entities.units
{
	import alternativa.engine3d.objects.Mesh;
	
	import net.akimirksnis.delta.game.core.Library;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.weapons.SMG;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	import net.akimirksnis.delta.game.utils.Utils;
	
	public class Walker2 extends Unit
	{	
		/*---------------------------
		Class vars and constants
		---------------------------*/	
		
		public static const MAX_HEALTH:int = 100;
		public static const SPEED:Number = 800;
		
		/*---------------------------
		Instance vars
		---------------------------*/		
		
		public function Walker2()
		{
			super();
			
			/*---------------------------
			Calls to Entity superclass
			---------------------------*/
			
			// Set type of the entity
			_type = UnitType.WALKER;
			
			// Set entity model
			setModel(Library.instance.getObjectByName(UnitType.WALKER).clone() as Mesh);
			
			// Set unique name
			name = "ControlledWalker2";
			
			// Setup event handlers
			setupEventHandlers();
			
			/*---------------------------
			Calls to DynamicEntity superclass
			---------------------------*/
			
			// Prepare animations [Unit + Entity]
			setupAnimations();
			
			/*---------------------------
			Calls to Unit superclass
			---------------------------*/
			
			// Setup collider
			setupCollider();			
			
			// Set basic parameters of this type of entity
			_health = MAX_HEALTH;
			_maxHealth = MAX_HEALTH;
			_maxWalkSpeed = SPEED;
			
			/*---------------------------
			- Set weapons available to unit
			- Set current weapon
			- Handle weapon models
			---------------------------*/
			
			_weapons.push(new SMG(this));
			_currentWeapon = _weapons[_currentWeaponIndex];
			
			for each(var w:Weapon in _weapons)
			{
				Utils.getDescendantByName(this, "Base_HumanRPalm").addChild(w);
				w.visible = false;				
			}
			
			_currentWeapon.visible = true;
			
			/*---------------------------
			Other
			---------------------------*/
			
			// ..
		}
		
		/*---------------------------
		Public methods
		---------------------------*/	
		
		/*---------------------------
		Setters/getters
		---------------------------*/
		
		public function get weapon():Weapon
		{
			return _currentWeapon;
		}
		
		public function set weapon(value:Weapon):void
		{
			_currentWeapon = value;
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		/**
		 * @inherit
		 */
		public override function dispose():void
		{
			super.dispose();
		}
	}
}