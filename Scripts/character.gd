extends CharacterBody3D

var gnd_speed = 14
var gnd_acceleration = 0.5
var gnd_decelaration = 0.5
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

var spray_air_speed = 3
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
var AnimPlayer = $BottomHeavyBase/AnimationPlayer

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
			$Graffiti/Timer.stop()
			SprayParticles.process_material.direction = Vector3(0,0.5,1)
			AnimPlayer.play("SprayBoost")
		
		#wall
		WallRunUp:
			velocity.y = speed - (velocity*Vector3(1,0,1)).length()
			AnimPlayer.play("WallRunUp")
		
		FrontLedgeGetUp:
			AnimPlayer.play("LedgeGetUp")
			
		
		#midair
		AirSprayBoost:
			$Graffiti/Timer.stop()
			direction = input_cam_dir.angle()
			rotation.y = rotation_angle(direction)
			speed+=spray_air_speed
			
			AnimPlayer.play("SprayBoost")
			SprayParticles.process_material.direction = Vector3(0,0.5,1)
			SprayParticles.emitting = true
			SprayParticles.lifetime = 0.3
			spray_charge-=1
		
		HuvIt:
			$Graffiti/Timer.stop()
			velocity.y = jump_force*1.5
			AnimPlayer.play("HuvIt")
			SprayParticles.process_material.direction = Vector3(0,-1,0)
			SprayParticles.emitting = true
			spray_charge-=1
		
		SkateJumping:
			coyote_timer = 0
			AnimPlayer.play("Jump")
			
			print(Time.get_ticks_msec())
			
			#velocity.y = jump_force
			velocity += (transform.basis * Vector3(0,jump_force,0))
			if old_state == SkatingCrouched:
				velocity += (transform.basis * Vector3(0,jump_force/2,0))
				#velocity.y += jump_force/2
		
		FastFall:
			AnimPlayer.play("FastFall",0)

func _exit_state(old_state,new_state):
	match old_state:
		FastFall:
			AnimPlayer.play_backwards("FastFall",0)
		Falling:
			if new_state == Skating:
				AnimPlayer.play("Land")
				speed = (velocity*Vector3(1,0,1)).length()
		FastFall:
			if new_state == Skating:
				AnimPlayer.play("Land")
				speed = (velocity*Vector3(1,0,1)).length()
		SprayBoost:
			if new_state == Skating:
				AnimPlayer.play("Land")
				speed = (velocity*Vector3(1,0,1)).length()
		WallRunUp:
			if new_state == Skating:
				AnimPlayer.play("Land")
				speed = (velocity*Vector3(1,0,1)).length()
			if new_state == Falling:
				AnimPlayer.play_backwards("WallRunUp")
		FrontLedgeGetUp:
			if new_state == Skating:
				AnimPlayer.play("Land")
				speed = (velocity*Vector3(1,0,1)).length()
		SkatingCrouched:
			AnimPlayer.play_backwards("Crouch")
		

func Graffitate(_wall_normal = null):
	if !$Graffiti/Ray.is_colliding():
		return
	
	var graffitate = $Graffiti/Art.duplicate()
	$"../".add_child(graffitate)
	
	graffitate.visible = true
	graffitate.position = $Graffiti/Ray.get_collision_point()
	if $Graffiti/Ray.get_collision_normal() != Vector3.UP:
		graffitate.look_at(graffitate.position+$Graffiti/Ray.get_collision_normal(),Vector3.UP)
		graffitate.rotate_object_local(Vector3(1,0,0),PI/2)
	
	graffitate.rotation.y = randf()*2*PI

func SkateIdle():
	Grounded()
	
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
		speed = 0
		state = Skating

func Grounded():
	var floor_rotation_x = (Vector2(get_floor_normal().x,get_floor_normal().y).angle()-PI/2)
	var floor_rotation_z = (Vector2(get_floor_normal().z,get_floor_normal().y).angle()-PI/2)
	
	rotation.x += (floor_rotation_z - rotation.x)/4
	rotation.z += (floor_rotation_x - rotation.z)/4
	
	
	#rotation.x
	
	floor_snap_length=0.5
	
	#jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		state = SkateJumping
	
	# On Air go to jumping
	if not is_on_floor():
		state = Falling
	
	#Ground SprayBoosting
	if Input.is_action_just_pressed("spray_boost") and spray_charge>0 and !spray_overheat:
		state = SprayBoost
	

func Skating():
	Grounded()
	
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
	
	#Skate Crouched
	if Input.is_action_pressed("fast_fall"):
			state = SkatingCrouched
	
	#Stop Skating
	if input_dir.length()<0.5:
		state = SkateIdle

func SprayBoost():
	Grounded()
	
	$Graffiti/Ray.target_position=Vector3(0,-3,0)
	if $Graffiti/Timer.is_stopped():
		Graffitate()
		if speed>0:
			$Graffiti/Timer.wait_time = 2/speed
			$Graffiti/Timer.start()
	#Rotation
	direction = rotate_toward(direction,input_cam_dir.angle(),deg_to_rad(25))
	rotation.y = rotation_angle(direction)
	
	#Directional Speed
	velocity.x = cos(direction)*(speed)
	velocity.z = sin(direction)*(speed)
	
	speed += (30-speed)/15
	spray_charge-=0.01
	SprayParticles.emitting = true
	
	if Input.is_action_just_released("spray_boost") or spray_charge < 0:
		SprayParticles.emitting = false
		state = Skating

func SkatingCrouched():
	Grounded()
	
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
	
	
	if Input.is_action_just_released("fast_fall"):
		state = Skating

func Skid():
	#velocity go to zero
	if !$Rays/GroundBelow.is_colliding():
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
		speed = 0
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
	
	var wall_angle = Vector2(get_wall_normal().z,get_wall_normal().x).angle()
	
	$Graffiti/Ray.target_position = get_wall_normal()*-3
	
	velocity.x = cos(direction)*(4)
	velocity.z = sin(direction)*(4)
	if is_on_wall():
		rotation.y = wall_angle
	
	#to Huv It
	if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		$Graffiti/Ray.target_position=get_wall_normal()*-3
		Graffitate()
		state = HuvIt
	
	#To Wall Jump
	if Input.is_action_just_pressed("jump") and is_on_wall():
		state = SkateJumping
		velocity.x = cos(rotation_angle(wall_angle))*(speed/-2)
		velocity.z = sin(rotation_angle(wall_angle))*(speed/-2)
	
	##To Ledge Get Up
	if is_on_wall() and !$Rays/Ledge.is_colliding():
		state = FrontLedgeGetUp
	
	#To falldown
	if velocity.y<=0 or is_on_ceiling():
		speed = 0
		velocity.x = 0
		velocity.z = 0
		state = Falling

func FrontLedgeGetUp():
	velocity.y = 13
	var wall_normal = Vector2(get_wall_normal().z,get_wall_normal().x).angle()+PI/2
	
	if is_on_wall():
		velocity.x = cos(-wall_normal)*(4)
		velocity.z = sin(-wall_normal)*(4)
	
	if is_on_floor():
		state = Skating
		#speed/=2
		#velocity.x = cos(direction)*(speed)
		#velocity.z = sin(direction)*(speed)
		#velocity.y = (0)
	
	if !$Rays/LedgeClear.is_colliding():
		state = Falling
		velocity.y=0
		velocity.x = cos(direction)*(speed)
		velocity.z = sin(direction)*(speed)
		#velocity.x = cos(direction)*(speed)/2
		#velocity.z = sin(direction)*(speed)/2

#Air

func AirSprayBoost():
	$Graffiti/Ray.target_position=Vector3(0,-5,5)
	if $Graffiti/Timer.is_stopped():
		Graffitate()
		if speed>0: 
			$Graffiti/Timer.wait_time = 2/speed
			$Graffiti/Timer.start()
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
	$Graffiti/Ray.target_position=Vector3(0,-5,5)
	if $Graffiti/Timer.is_stopped():
		Graffitate()
		if speed>0:
			$Graffiti/Timer.wait_time = 2/speed
			$Graffiti/Timer.start()
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

#when in midair a lot of code overlaps so its abstracted here in midair
func MidAir():
	#rotation.x += (0 - rotation.x)/8
	#rotation.z += (0 - rotation.z)/8
	
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
	
	## to falling
	#if velocity.y<=0 and !(Input.is_action_pressed("fast_fall")):
		#state = Falling
	
	# to WallRunUp
	var wall_angle = Vector2(get_wall_normal().x,get_wall_normal().z).angle()
	
	if is_on_wall() and (velocity*Vector3(1,1,1)).length()<speed:
		#print(speed)
		if abs(angle_difference(rotation_angle(rotation.y),wall_angle))>deg_to_rad(150):
			#print(velocity.y)
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
	
	velocity += get_gravity() * delta * transform.basis
	
	velocity_towards_input(air_speed,air_acceleration)

func SkateJumping():
	rotation.y = rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),deg_to_rad(3))
	
	#to Falling
	if velocity.y<=0:
		state = Falling
	
	MidAir()

func FastFall():
	velocity += get_gravity() * delta * 4
	
	if (Input.is_action_just_released("fast_fall")):
		state = Falling
	
	MidAir()

func Falling():
	#Jump if Coyote Time
	if coyote_timer>0:
		coyote_timer-=1
		if Input.is_action_just_pressed("jump"):
			state = SkateJumping
			return
	
	#Heavier When Falling
	velocity += get_gravity() * delta * transform.basis/2
	
	#Rotate to input
	#rotation.y = rotation_angle(input_cam_dir.angle())
	rotation.y = rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),air_rotation_speed)
	
	MidAir()

func velocity_towards_input(_speed, acceleration):
	var velocity2d = Vector2(velocity.x,velocity.z)
	
	# Little movement Falling
	if abs(input_cam_dir.angle()-velocity2d.angle())>0.2:
		velocity.x = move_toward(velocity.x,input_cam_dir.x*speed,acceleration)
		velocity.z = move_toward(velocity.z,input_cam_dir.y*speed,acceleration)
	

func _physics_process(v_delta: float) -> void:
	if (has_node("SprayParticles")):
		$SprayParticles.reparent($BottomHeavyBase/Character/Body2/RShoulder/RArm/ElbowPads/RLowerArm/Hand2/Hand,false)
	
	# Raw input data
	input_dir = Input.get_vector("left", "right", "up", "down")
	
	# Input data rotated for camera 
	input_cam_dir = input_dir.rotated(-(Camera.rotation.y))
	
	# Input Straight Up with left and right data
	input_rot = input_cam_dir.rotated(rotation.y)
	
	#speedometer
	$UI/SpeedMeter.set_point_position(1,Vector2(0,-speed*3))
	#spray meter and overheat
	$UI/SprayMeter.set_point_position(1,Vector2(0,-spray_charge*55))
	if spray_overheat:
		$UI/SprayMeter.default_color = Color(1,0,0)
	else:
		$UI/SprayMeter.default_color = Color(0.5,0.5,1)
	
	if spray_charge<= 0.05:
		spray_overheat=true
	if spray_charge >= 2:
		spray_overheat=false
	
	##DEBUG
	$UI/Debug/Line2D.set_point_position(1,(100*Vector2(cos(direction),sin(direction)).rotated(PI/2)))
	#$UI/Debug/Line2D2.set_point_position(1,(100*Vector2(cos(wall_angle),sin(wall_angle))))
	
	delta = v_delta
	
	if speed<0: speed = 0
	
	state.call()
	
	$UI/Debug/State.text = str(state) + "\n" + str(previous_state)
	
	move_and_slide()

# Function for converting beetween rotation on the 3D and rotation as vector2 angles
func rotation_angle(angle : float):
	return -angle-PI/2
