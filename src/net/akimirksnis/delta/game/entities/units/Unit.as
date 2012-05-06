package net.akimirksnis.delta.game.entities.units
{
	import alternativa.engine3d.animation.AnimationClip;
	import alternativa.engine3d.collisions.EllipsoidCollider;
	import alternativa.engine3d.core.BoundBox;
	import alternativa.engine3d.materials.FillMaterial;
	import alternativa.engine3d.objects.Mesh;
	import alternativa.engine3d.objects.WireFrame;
	import alternativa.engine3d.primitives.Box;
	import alternativa.engine3d.primitives.GeoSphere;
	
	import flash.events.Event;
	import flash.geom.Vector3D;
	import flash.utils.getTimer;
	
	import net.akimirksnis.delta.game.entities.AnimationType;
	import net.akimirksnis.delta.game.entities.Entity;
	import net.akimirksnis.delta.game.entities.EntityType;
	import net.akimirksnis.delta.game.entities.weapons.Weapon;
	import net.akimirksnis.delta.game.library.Library;
	import net.akimirksnis.delta.game.utils.Globals;
	import net.akimirksnis.delta.game.utils.Utils;
	
	public class Unit extends Entity
	{	
		/*---------------------------
		Movement, time tracking
		---------------------------*/
		
		private var elapsed:Number
		private var timeNow:int;
		private var lastTime:int;
		
		private var up:Vector3D = new Vector3D(0, 0, 1);
		private var down:Vector3D = new Vector3D(0, 0, -1);
		private var forward:Vector3D = new Vector3D();
		private var right:Vector3D;		
		private var accelerationAmount:Number = 100;
		private var accelerationAmountInAir:Number = 25;
		private var dampingAmount:Number = 50;
		private var dampingAmountInAir:Number = 8;
		private var gravityAccelerationAmount:Number = 35;
		private var velocity:Vector3D = new Vector3D();
		private var damping:Vector3D = new Vector3D();
		private var onGround:Boolean = false;
		private var fallSpeed:Number = 0;
		private var jumpTick:Boolean = false;
		private var displacement:Vector3D = new Vector3D();
		private var source:Vector3D = new Vector3D();
		private var collisionPoint:Vector3D = new Vector3D();
		private var collisionPlane:Vector3D = new Vector3D();	
		
		/*---------------------------
		Collisions
		---------------------------*/
		
		private var collider:EllipsoidCollider;
		
		/*---------------------------
		Animation types
		---------------------------*/
		
		private var aniIdle:AnimationClip;
		private var aniMove:AnimationClip;
		private var aniAttack:AnimationClip;
		private var aniDeath:AnimationClip;
		
		/*---------------------------
		Unit characteristics
		---------------------------*/
		
		protected var _speed:int = 500;
		protected var _jumpHeight:int = 500;
		protected var _maxHealth:int;
		protected var _health:int;
		protected var _damage:int;
		protected var _attackSpeed:int;
		
		/*---------------------------
		Weapons and shooting
		---------------------------*/
		
		protected var _currentWeapon:Weapon;
		protected var _currentWeaponIndex:int = 0;
		protected var _weapons:Vector.<Weapon> = new Vector.<Weapon>();	
		
		/**
		 * Class constructor.
		 */
		public function Unit()
		{
			super();
		}
		
		/*---------------------------
		Setup methods
		---------------------------*/
		
		protected override function setupAnimations():void
		{
			super.setupAnimations();
			
			// Get all animations for this type of entity model
			var animation:AnimationClip = Library.instance.getAnimationByName(super.type).clone();
			var animationFrames:String = Library.instance.getPropertiesByName(super.type)["animations"];
			var timeBounds:Vector.<Number> = new Vector.<Number>();
			
			animation.attach(model, true);
			
			if(animationFrames != null || animationFrames != "")
			{
				// Iterate through split parts of string
				for each (var sub:String in animationFrames.split("/"))
				{
					var subsub:Array = sub.split("-");
					
					// Split, parseint and push to vector exact frame bound numbers
					timeBounds.push(parseFloat(subsub[0]));
					timeBounds.push(parseFloat(subsub[1]));
				}
				
				if(timeBounds.length < 2)
					throw new Error("[Unit] Less than two animation bounds found.");
				
				aniIdle = animation.slice(timeBounds[0] / 30, timeBounds[1] / 30);
				aniMove = animation.slice(timeBounds[2] / 30, timeBounds[3] / 30);
				
				// Add animation slices to switcher
				aniSwitcher.addAnimation(aniIdle);
				aniSwitcher.addAnimation(aniMove);
				//aniSwitcher.addAnimation(aniAttack);
				//aniSwitcher.addAnimation(aniDeath);
				
				// Attach switcher as controller`s root
				aniController.root = aniSwitcher;	
				
				// Init idle animation
				aniSwitcher.activate(aniIdle, 0.1);
				
				// Register loop callback
				Globals.gameCore.addLoopCallback(aniController.update);
			} else {
				throw new Error("[Unit] Animation properties of the unit not found.");
			}
		}
		
		protected function setupCollider(collider:EllipsoidCollider):void
		{
			this.collider = collider;
			
			// Collision spehere visualisation
			if(Globals.debugMode)
			{
				var rutul:GeoSphere = new GeoSphere(1,10,false,new FillMaterial(0xAAFF00, 0.4));
				Globals.renderer.uploadResources(rutul.getResources());
				this.model.addChild(rutul);
				rutul.scaleX = collider.radiusX;
				rutul.scaleY = collider.radiusY;
				rutul.scaleZ = collider.radiusZ;
				rutul.z = this.model.boundBox.maxZ / 2;
			}
		}
		
		/*---------------------------
		Public methods
		---------------------------*/
		
		public function think():void
		{
			move();
		}
		
		/*---------------------------
		Movement
		---------------------------*/
		
		/**
		 * Jumps by adding velocity along z axis.
		 */
		public function jump():void
		{
			// Allow jumping if unit is on ground and at least two frames passed since last jump
			if(onGround)
			{
				addVelocityXYZ(0, 0, _jumpHeight);
				trace("jumping...");
				jumpTick = true;
			}
		}
		
		/**
		 * Adds velocity to the unit. Each property of the vector corresponds 
		 * to the direction of the movement. Property w is not used. It`s 
		 * better to use addVelocityXYZ method since it doesn`t require to
		 * create new Vector3D object.
		 * 
		 * @param movement Vector defining directions for unit movement.
		 */
		public function addVelocity(inputVelocity:Vector3D):void
		{
			velocity.incrementBy(inputVelocity);
		}
		
		/**
		 * Adds velocity to the unit. Each parameter corresponds 
		 * to the direction of the movement.
		 * 
		 * @param x Velocity along x axis.
		 * @param y Velocity along y axis.
		 * @param z Velocity along z axis.
		 */
		public function addVelocityXYZ(x:Number, y:Number, z:Number):void
		{
			velocity.x += x;
			velocity.y += y;
			velocity.z += z;			
		}
		
		/**
		 * Adds velocity depending on user input.
		 * 
		 * @param input Defines user input. Each of x/y/z variables
		 * marks the amount of movement for each axis. This data is
		 * translated depending on rotation of the unit.
		 */
		public function addVelocityFromInput(input:Vector3D):void
		{
			// Reset vectors
			up.setTo(0, 0, 1);
			
			/*----------------------
			Calculate direction
			----------------------*/
			
			// Calculate forward vector from unit rotation
			forward.x = Math.cos(model.rotationZ - Utils.HALF_PI);
			forward.y = Math.sin(model.rotationZ - Utils.HALF_PI);
			forward.z = 0;
			
			// Calculate right vector from cross product of forward and up vectors
			right = up.crossProduct(forward);
			
			// Scale movement vectors depending to keyboard input
			forward.scaleBy(input.y);
			right.scaleBy(-input.x);
			up.scaleBy(input.z);		
			
			// Sum up all regular movement vectors and normalize result
			forward.incrementBy(right);
			forward.incrementBy(up);
			forward.normalize();
			
			/*----------------------
			Handle velocity
			----------------------*/
			
			// Scale by acceleration
			if(onGround)
				forward.scaleBy(accelerationAmount);
			else
				forward.scaleBy(accelerationAmountInAir);
			
			// Current speed (in x/y dimension)
			var length:Number = Math.sqrt(Math.pow(velocity.x, 2) + Math.pow(velocity.y, 2));
			
			//trace("current speed: " + length);
			
			if(length >= _speed)
			{
				if(velocity.x * forward.x < 0)
				{
					velocity.x += forward.x;
				}
				if(velocity.y * forward.y < 0)
				{
					velocity.y += forward.y;
				}				
			} else {				
				// todo: maybe limit to exact speed
				velocity.incrementBy(forward);
			}			
			
			/*----------------------
			Handle damping
			----------------------*/
			
			damping.copyFrom(velocity);
			damping.z = 0;
			damping.normalize();
			
			if(onGround)
				damping.scaleBy(dampingAmount);
			else
				damping.scaleBy(dampingAmountInAir);
			
			var prevX:Number = velocity.x,
				prevY:Number = velocity.y;
			
			velocity.decrementBy(damping);
			
			// Set speed to zero if it has been inverted
			velocity.x = (velocity.x * prevX < 0) ? 0 : velocity.x;
			velocity.y = (velocity.y * prevY < 0) ? 0 : velocity.y;
		}
		
		/**
		 * Moves the unit according to velocityVector.
		 */
		public function move():void
		{		
			/*----------------------
			Handle animations
			----------------------*/
			
			// If there is be movement along X or Y axis - animate
			// todo: stuff
			if(velocity.length > 0)
			{	
				this.animation = AnimationType.UNIT_MOVE;
			} else {
				this.animation = AnimationType.UNIT_IDLE;
			}
			
			/*----------------------
			Hadle gravity
			----------------------*/
			
			// Get current time
			timeNow = getTimer();
			
			// Calculate time since last tick (in seconds)
			elapsed = (timeNow - lastTime) / 1000;
			
			// Set current ellipsoid position
			source.setTo(model.x, model.y, model.z + this.model.boundBox.maxZ / 2);
			
			// Check for surface under the character				
			onGround = collider.getCollision(
				source, 
				down,
				collisionPoint,
				collisionPlane,
				library.map.collisionMesh
			);
			//trace("on ground :"+onGround);
			
			if(onGround && !jumpTick)
			{
				velocity.z = 0;
			} else {
				if(velocity.z > -Globals.GRAVITY)
				{
					velocity.z -= gravityAccelerationAmount;					
				}
				
				// Avoid additional jumping next tick if space is still pressed
				onGround = jumpTick = false;
			}
			
			/*----------------------
			Calculate displacement and calculate final unit position
			----------------------*/
			
			// Distance to move along all axes
			// Forumula: s = v * t			
			displacement.setTo(
				velocity.x * elapsed,
				velocity.y * elapsed,
				velocity.z * elapsed
			);
			
			//trace("final velocity: "+velocity);
			
			// Calculate final destination point (taking in the account collisions and gravity)
			var destination:Vector3D = collider.calculateDestination(source, displacement, library.map.collisionMesh);
			
			// Set new coordinates of this unit
			model.x = destination.x;
			model.y = destination.y;
			model.z = destination.z - this.model.boundBox.maxZ / 2;			
			
			//trace("unit pos: " + model.z);
			
			// Last time is now
			lastTime = timeNow;		
		}
		
		/*---------------------------
		Per-frame input handlers
		---------------------------*/
		
		/**
		 * Uses unit`s current weapon primary fire.
		 */
		public function usePrimaryFire():void
		{
			_currentWeapon.usePrimaryFire();
		}
		
		/**
		 * Uses unit`s current weapon secondary fire.
		 */
		public function useSecondaryFire():void
		{
			_currentWeapon.useSecondaryFire();
		}
		
		/*---------------------------
		Helpers
		---------------------------*/
		
		/*---------------------------
		Getters/setters
		---------------------------*/
		
		protected function set animation(animation:String):void
		{
			switch(animation)
			{
				case AnimationType.UNIT_IDLE:
					currentAnimation = animation;
					aniSwitcher.activate(aniIdle);
					break;
				case AnimationType.UNIT_MOVE:
					currentAnimation = animation;
					aniSwitcher.activate(aniMove);
					break;
				case AnimationType.UNIT_ATTACK:
					currentAnimation = animation;
					aniSwitcher.activate(aniAttack);
					break;
				case AnimationType.UNIT_DEATH:
					currentAnimation = animation;
					aniSwitcher.activate(aniDeath);
					break;
				default:
					trace("[Unit] Animation could not be set. Unknown animation: " + animation);
			}
		}
		
		public function get maxHealth():int
		{
			return _maxHealth;
		}
		
		public function get health():int
		{
			return _health;
		}
		
		public function get damage():int 
		{
			return _damage;
		}
		
		public function get speed():int 
		{
			return _speed;
		}
		
		public function get attackSpeed():int 
		{
			return _attackSpeed;
		}
		
		/*---------------------------
		Dispose
		---------------------------*/
		
		public override function dispose():void
		{
			Globals.gameCore.removeLoopCallbackPre(aniController.update);
			super.dispose();
		}
	}
}