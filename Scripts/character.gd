extends CharacterBody3D

var gnd_speed = 14
var gnd_acceleration = 0.5
var gnd_decelaration = 0.4
var gnd_speed_cap_deceleration = 0.2
var gnd_crouched_deceleration = 0.05
#var gnd_rotation_speed = deg_to_rad(7)

var air_speed = 7
var air_acceleration = 0.1
var air_rotation_speed = deg_to_rad(3)

var skid_decelaration = 0.5
var to_skid_rad_threshold = deg_to_rad(45)
var out_of_skid_rad_threshold = deg_to_rad(1)

var jump_force : float = 7

var coyote_time = 20

var spray_air_speed = 9
var spray_gnd_speed = 0.5
var turn_deg_penalty = 0.01

##Variables for movement
#Inputs
var input_dir = Vector2.ZERO
var input_rot = Vector3.ZERO
var input_cam_dir = Vector2.ZERO
#movement
var direction = 0.0
var speed = 0.0
var coyote_timer = coyote_time
#Spray Boost
var spray_charge = 2
var spray_overheat = false

#State
var state = SkateIdle:
	set(new_state):
		previous_state = state
		state = new_state
		set_state(new_state)
var previous_state = null


# SkateIdle Skating Jumping

#Shared Delta beetween functions
var delta = 0.0

#Nodes
@onready
var SprayParticles = $SprayParticles
@onready
var Camera = $"../CameraGimbal"
@onready
var AnimPlayer = $blockbench_export/AnimationPlayer

func set_state(new_state):
	if previous_state!=null:
		_exit_state(previous_state,new_state)
	if new_state!=null:
		_enter_state(new_state,previous_state)


func _enter_state(new_state, old_state):
	match new_state:
		#land
		SkateIdle:
			AnimPlayer.play("Idle",1)
			speed=0
			velocity=Vector3(0,0,0)
		
		Skating:
			if old_state == SkateIdle or old_state == Skid:
				AnimPlayer.play("Push")
			#elif old_state == Falling or old_state == FastFall or old_state == SkatingCrouched:
				#AnimPlayer.play("Land")
		
		SkatingCrouched:
			AnimPlayer.play("Crouch")
		
		Skid:
			AnimPlayer.play("SkidLand")
		
		SprayBoost:
			SprayParticles.process_material.direction = Vector3(0,0.5,1)
			AnimPlayer.play("SprayBoost")
		
		#wall
		WallRunUp:
			AnimPlayer.play("WallRunUp")
			velocity.y = speed - velocity.length()
		
		FrontLedgeGetUp:
			AnimPlayer.play("FrontLedgeGetUp")
			
		
		#midair
		AirSprayBoost:
			direction = input_cam_dir.angle()
			rotation.y = rotation_angle(direction)
			speed+=spray_air_speed
			
			AnimPlayer.play("SprayBoost")
			SprayParticles.process_material.direction = Vector3(0,0.5,1)
			SprayParticles.emitting = true
			SprayParticles.lifetime = 0.3
			spray_charge-=1
		
		HuvIt:
			velocity.y = jump_force*1.5
			AnimPlayer.play("HuvIt")
			SprayParticles.process_material.direction = Vector3(0,-1,0)
			SprayParticles.emitting = true
			spray_charge-=1
		
		SkateJumping:
			coyote_timer = 0
			AnimPlayer.play("Jump")
			
			velocity.y = jump_force
			if old_state == SkatingCrouched:
				velocity.y += jump_force/2
		
		FastFall:
			AnimPlayer.play("FastFall",0)

func _exit_state(old_state,new_state):
	match old_state:
		FastFall:
			AnimPlayer.play_backwards("FastFall",0)
		Falling:
			if new_state == Skating:
				AnimPlayer.play("Land")
		FastFall:
			if new_state == Skating:
				AnimPlayer.play("Land")
		SprayBoost:
			if new_state == Skating:
				AnimPlayer.play("Land")
		WallRunUp:
			if new_state == Skating:
				AnimPlayer.play("Land")
			if new_state == Falling:
				AnimPlayer.play_backwards("WallRunUp")
		FrontLedgeGetUp:
			if new_state == Skating:
				AnimPlayer.play("Land")
		SkatingCrouched:
			AnimPlayer.play_backwards("Crouch")
		


func SkateIdle():
	#recharge Spray
	if spray_charge<2:
		spray_charge += 0.03
	
	if input_dir.length()>0.5:
		rotation.y = rotation_angle(input_cam_dir.angle())
	
	velocity.x = move_toward(velocity.x,0,gnd_decelaration)
	velocity.z = move_toward(velocity.z,0,gnd_decelaration)
	
	if not is_on_floor():
		state = Falling
	
	if input_dir:
		state = Skating

func Skating():
	# On Air go to jumping
	if not is_on_floor():
		state = Falling
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		state = SkateJumping
	
	#Skate Crouched
	if Input.is_action_pressed("fast_fall"):
			state = SkatingCrouched
	
	#recharge Spray
	if spray_charge<2:
		spray_charge += 0.03
	
	#Rotation
	rotation.y=rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),(PI/speed))
	
	#decelerate if you turn too much
	if angle_difference(rotation_angle(rotation.y),direction)>0.05 and speed>0:
		speed-=rad_to_deg(abs(input_rot.x))*turn_deg_penalty
	
	direction = rotation_angle(rotation.y)
	
	#speed Direction
	if speed<gnd_speed:
		speed = move_toward(speed,-input_rot.y*gnd_speed,gnd_acceleration)
	else:
		speed = move_toward(speed,-input_rot.y*gnd_speed,gnd_speed_cap_deceleration)
	velocity.x = cos(direction)*(speed)
	velocity.z = sin(direction)*(speed)

	#Ground SprayBoosting
	if Input.is_action_pressed("spray_boost") and spray_charge>0 and !spray_overheat:
		state = SprayBoost
	
	#Stop Skating
	if input_dir.length()<0.5:
		state = SkateIdle

func SprayBoost():
	#Rotation
	direction = rotate_toward(direction,input_cam_dir.angle(),deg_to_rad(25))
	rotation.y=rotation_angle(direction)
	
	#Directional Speed
	velocity.x = cos(direction)*(speed)
	velocity.z = sin(direction)*(speed)
	
	speed+=spray_gnd_speed
	spray_charge-=0.05
	SprayParticles.emitting = true
	
	if Input.is_action_just_released("spray_boost") or spray_charge < 0:
		SprayParticles.emitting = false
		state = Skating

func SkatingCrouched():
	#Rotation
	rotation.y=rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),(PI/speed))
	
	#decelerate if you turn too much
	if angle_difference(rotation_angle(rotation.y),direction)>0.05 and speed>0:
		speed-=rad_to_deg(abs(input_rot.x))*turn_deg_penalty
	
	direction = rotation_angle(rotation.y)
	
	#speed direction
	speed = move_toward(speed,-input_rot.y*gnd_speed,gnd_crouched_deceleration)
	velocity.x = cos(direction)*(speed)
	velocity.z = sin(direction)*(speed)
	
	#recharge double Spray
	if spray_charge<2:
		spray_charge += 0.06
	
	if Input.is_action_just_pressed("jump"):
		state = SkateJumping
	
	if Input.is_action_just_released("fast_fall"):
		state = Skating

func Skid():
	#velocity go to zero
	if !$EdgeRaycast.is_colliding():
		velocity.x = 0
		velocity.z = 0
	velocity.x = move_toward(velocity.x,0,skid_decelaration)
	velocity.z = move_toward(velocity.z,0,skid_decelaration)
	speed = move_toward(speed,0,skid_decelaration)
	
	#rotate speed direction to your facing direction
	direction = rotate_toward(direction,rotation_angle(rotation.y),PI/(speed*1.5))
	
	if not is_on_floor():
		state = Falling
	
	#if direction and rotation align go to skating
	if abs(angle_difference(direction,rotation_angle(rotation.y)))<out_of_skid_rad_threshold:
		speed=0
		state = Skating
	
	if !input_dir or is_zero_approx(speed):
		state = SkateIdle

#Wall

#func WallRide():
	#velocity += get_gravity() * delta/3
	#
	#var wall_normal = Vector2(get_wall_normal().x,get_wall_normal().z).rotated(PI/4).angle()
	#
	#rotation.y = rotation_angle(-wall_normal)
	#
	#velocity.x = cos(-wall_normal)*(speed)
	#velocity.z = sin(-wall_normal)*(speed)
	#
	#if !is_on_wall():
		#state = Falling

func WallRunUp():
	velocity += get_gravity() * delta
	
	var wall_normal = Vector2(get_wall_normal().z,get_wall_normal().x).angle()+PI/2
	
	velocity.x = cos(direction)*(4)
	velocity.z = sin(direction)*(4)
	if is_on_wall():
		print(wall_normal)
		rotation.y = rotation_angle(-wall_normal)
		
	
	#to Huv It
	if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		state = HuvIt
	
	#To Wall Jump
	if Input.is_action_just_pressed("jump") and is_on_wall():
		state = SkateJumping
		velocity.x = cos(wall_normal)*(speed/2)
		velocity.z = sin(wall_normal)*(speed/2)
	
	##To Ledge Get Up
	if is_on_wall() and !$LedgeRay.is_colliding():
		#state = FrontLedgeGetUp
		state = Skating
		velocity.y=0
		velocity.x = cos(-wall_normal)*(speed)
		velocity.z = sin(-wall_normal)*(speed)
		var point_to_snap = Vector2(1.5,0).rotated(rotation_angle(rotation.y))
		position+=Vector3(point_to_snap.x,4,point_to_snap.y)
		floor_snap_length=5
		apply_floor_snap()
		floor_snap_length=0.1
	
	#To falldown
	if velocity.y<=0:
		speed=0
		velocity.x=0
		velocity.z=0
		state = Falling

func FrontLedgeGetUp():
	apply_floor_snap()
	velocity.y = (speed)/2
	var wall_normal = Vector2(get_wall_normal().x,get_wall_normal().z).angle()
	
	velocity.x = cos(-wall_normal)*(14)
	velocity.z = sin(-wall_normal)*(14)
	
	if is_on_floor():
		state = Skating
		speed/=2
		velocity.x = cos(direction)*(speed)
		velocity.z = sin(direction)*(speed)
		velocity.y = (0)
	
	if !is_on_wall():
		state = Falling
		velocity.x = cos(direction)*(speed)/2
		velocity.z = sin(direction)*(speed)/2
#Air

func AirSprayBoost():
	#Rotation
	direction = rotate_toward(direction,input_cam_dir.angle(),deg_to_rad(2))
	rotation.y=rotation_angle(direction)
	
	#Directional Speed
	velocity.x = cos(direction)*(speed)
	velocity.z = sin(direction)*(speed)
	
	if Input.is_action_just_pressed("jump") and spray_charge>=1 and !spray_overheat:
		state = HuvIt
	
	
	if !SprayParticles.emitting:
		state = Falling

func HuvIt():
	##gravity
	#velocity += get_gravity() * delta
	#
	#velocity_towards_input(air_speed,air_acceleration)
	#
	##To Spray Boost
	#if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		#state = AirSprayBoost
	#
	##To falling
	#if velocity.y>=0:
		#state = Falling
	
	MidAir()
	
	#if !SprayParticles.emitting:
		#state = Falling

func MidAir():
	velocity += get_gravity() * delta
	
	velocity_towards_input(air_speed,air_acceleration)
	
	#to Huv It
	if Input.is_action_just_pressed("jump") and spray_charge>=1 and !spray_overheat:
		state = HuvIt
		return
	
	#to Spray Boost
	if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		state = AirSprayBoost
		return
	
	#to fast fall
	if (Input.is_action_just_pressed("fast_fall")):
		state = FastFall
	
	# to falling
	if velocity.y<=0 and !(Input.is_action_pressed("fast_fall")):
		state = Falling
	
	var wall_angle = Vector2(get_wall_normal().x,get_wall_normal().z).angle()
	var velocity2d = Vector2(velocity.x,velocity.z)
	if is_on_wall() and velocity.length()<speed: 
		if abs(angle_difference(rotation_angle(rotation.y),wall_angle))>deg_to_rad(150):
			state = WallRunUp
			return
		#else:
			#state = WallRide
	
	#To Skating or Skidding
	if is_on_floor():
		coyote_timer = coyote_time
		# On floor go back to skating or to skid if you're not rotated correctly
		if abs(angle_difference(direction,rotation_angle(rotation.y)))<to_skid_rad_threshold:
			state = Skating
		else:
			state = Skid
	

func SkateJumping():
	rotation.y = rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),deg_to_rad(3))
	
	MidAir()
	
	#velocity += get_gravity() * delta
	#
	#velocity_towards_input(air_speed,air_acceleration)
	#
	##to Huv It
	#if Input.is_action_just_pressed("jump") and spray_charge>=1 and !spray_overheat:
		#state = HuvIt
	#
	##to Spray Boost
	#if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		#state = AirSprayBoost
	#
	##to fast fall
	#if (Input.is_action_pressed("fast_fall")):
		#state = FastFall
	#
	##to Falling
	#if velocity.y<=0:
		#state = Falling

func FastFall():
	velocity += get_gravity() * delta * 4
	
	MidAir()
	#velocity_towards_input(air_speed,air_acceleration)
	#
	##to Spray Boost
	#if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		#state = AirSprayBoost
	#
	##stop fast falling
	#if (Input.is_action_just_released("fast_fall")):
		#state = Falling
	#
	##to skating
	#if is_on_floor():
		#state = Skating

func Falling():
	#Jump if Coyote Time
	if coyote_timer>0:
		coyote_timer-=1
		if Input.is_action_just_pressed("jump"):
			state = SkateJumping
			return
	
	#Rotate to input
	#rotation.y = rotation_angle(input_cam_dir.angle())
	rotation.y = rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),air_rotation_speed)
	
	MidAir()
	
	#gravity
	#velocity += get_gravity() * delta
	#
	#velocity_towards_input(air_speed,air_acceleration)
	#
	## Huv It
	#if Input.is_action_just_pressed("jump") and spray_charge>=1 and !spray_overheat:
		#state = HuvIt
	#
	##Spray Boost
	#if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		#state = AirSprayBoost
	#
	##to Fast Fall
	#if (Input.is_action_pressed("fast_fall")):
		#state = FastFall
	#
	##To Skating or Skidding
	#if is_on_floor():
		#coyote_timer = coyote_time
		## On floor go back to skating or to skid if you're not rotated correctly
		#if abs(angle_difference(direction,rotation_angle(rotation.y)))<to_skid_rad_threshold:
			#state = Skating
		#else:
			#state = Skid

func velocity_towards_input(speed, acceleration):
	var velocity2d = Vector2(velocity.x,velocity.z)
	
	# Little movement Falling
	if abs(input_cam_dir.angle()-velocity2d.angle())>0.2:
		velocity.x = move_toward(velocity.x,input_cam_dir.x*speed,acceleration)
		velocity.z = move_toward(velocity.z,input_cam_dir.y*speed,acceleration)
	speed = velocity.length()

func _physics_process(v_delta: float) -> void:
	if (has_node("SprayParticles")):
		$SprayParticles.reparent($blockbench_export/Character/Body2/RShoulder/RArm/ElbowPads/RLowerArm/Hand2/Hand,false)
	
	# Raw input data
	input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Input data rotated for camera 
	input_cam_dir = input_dir.rotated(-(Camera.rotation.y))
	
	# Input Straight Up with left and right data
	input_rot = input_cam_dir.rotated(rotation.y)
	
	#speedometer
	$SpeedMeter.set_point_position(1,Vector2(0,-speed*3))
	#spray meter and overheat
	$SprayMeter.set_point_position(1,Vector2(0,-spray_charge*55))
	if spray_overheat:
		$SprayMeter.default_color = Color(1,0,0)
	else:
		$SprayMeter.default_color = Color(0.5,0.5,1)
	
	if spray_charge<= 0.05:
		spray_overheat=true
	if spray_charge >= 2:
		spray_overheat=false
	
	#var wall_angle = Vector2(get_wall_normal().x,get_wall_normal().z).angle()
	#var velocity2d = Vector2(velocity.x,velocity.z)
	#print(rad_to_deg())
	
	##DEBUG
	$Line2D.set_point_position(1,(100*Vector2(cos(direction),sin(direction)).rotated(PI/2)))
	#$Line2D2.set_point_position(1,(100*Vector2(cos(wall_angle),sin(wall_angle))))
	
	delta = v_delta
	
	if speed<0: speed=0
	
	state.call()
	
	move_and_slide()

# Function for converting beetween rotation on the 3D and rotation as vector2 angles
func rotation_angle(angle : float):
	return -angle-PI/2
