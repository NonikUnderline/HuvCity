extends CharacterBody3D

class_name NewCharacter

#Variables
#grounded
var gnd_max_speed = 20
#var gnd_maximum_speed = 35
var gnd_acceleration = 1
var gnd_spd_cap_decelaration = 0.1
var gnd_decelaration = 2
var gnd_rotation = 0.5

#air
var air_speed = 0.15
var jump_velocity = 9

#Movement
var speed = 0.0
var input_dir : Vector2
var input_cam_dir : Vector2
var last_wall_normal : Vector3

#direction
var direction : Quaternion = Quaternion.IDENTITY
var direction_x : Quaternion = Quaternion.IDENTITY

var air_direction : Quaternion = Quaternion.IDENTITY

var g_multiplier = 1.0

#State
var delta = 0.0
var state : String = "SkateIdle":
	set(new_state):
		previous_state = state
		state = new_state
		set_state(new_state)
var previous_state = "null"

##Inventory
@export
var paint_weapon : PaintWeapon
@export
var movement_ride : MovementRide

#Refs
@onready
var Camera = $"../../CameraGimbal"
@onready
var GroundRay = $Rays/Ground 
@onready
var AlignFloorRay = $Rays/AlignFloor
@onready
var Coll = $Colls/CustomColl
@onready
var Anim = $Character/AnimationTree


##Multiplayer
# Set by the authority, synchronized on spawn.
@export var player := 1 :
	set(id):
		player = id
		# Give authority over the player input to the appropriate peer.
		set_multiplayer_authority(id)


func set_state(new_state):
	if previous_state!=null:
		_exit_state(previous_state,new_state)
	if new_state!=null:
		_enter_state(new_state,previous_state)


func _enter_state(new_state, old_state):
	match new_state:
		"Jumping":
			Anim.set("parameters/conditions/Jump", true)
			
			velocity.y = jump_velocity
			
			g_multiplier = 1
			state = "Falling"
		"Skating":
			if old_state == "Falling":
				Anim.set("parameters/conditions/Jump", false)
				Anim.set("parameters/conditions/FastFall", false)
				movement_ride.WhenLanding()
			else:
				Anim.set("parameters/conditions/Moving", true)
				
			#if is_on_ground() and is_on_ground()[0].rotation!=Vector3.ZERO:
				#speed += min(abs(velocity.y/gnd_max_speed/2),2)
		"Falling":
			pass
			#if GroundRay.get_collision_normal()!=Vector3.ZERO:
				#velocity.y += min(abs(speed/gnd_max_speed),2)
		"SkateIdle":
			Anim.set("parameters/conditions/Moving", false)

func _init() -> void:
	motion_mode = MOTION_MODE_FLOATING
	floor_snap_length = 0.5
	

func _exit_state(old_state,new_state):
	match old_state:
		pass
			

func SkateIdle():
	universal_rotation()
	
	global_transform.basis = Basis((direction_x * direction).normalized())
	
	velocity.x = move_toward(velocity.x, 0, gnd_decelaration)
	velocity.z = move_toward(velocity.z, 0, gnd_decelaration)
	speed = move_toward(speed, 0, gnd_decelaration)
	
	if (direction_x.dot(direction.inverse()*quaternion))<0.95:
		velocity.y += get_gravity().y * delta
	
	if input_dir:
		direction = Quaternion(Vector3.RIGHT,Vector3(input_cam_dir.x,0,-input_cam_dir.y))
		state = "Skating"
	
	if Input.is_action_just_pressed("jump") and GroundRay.is_colliding():
		state = "Jumping"
	
	if Input.is_action_pressed("spray_boost") and paint_weapon.GroundUse() or Input.is_action_pressed("fast_fall"):
		state = "Skating"
		direction = quaternion
		speed = 18

func Skating():
	##State Behavior
	if input_dir or Input.is_action_pressed("fast_fall"):
		if !Input.is_action_pressed("fast_fall") and !Input.is_action_pressed("spray_boost"):
			speed = move_toward(speed, gnd_max_speed*input_cam_dir.length(), gnd_acceleration)
		elif speed>gnd_max_speed:
			speed = move_toward(speed, gnd_max_speed, gnd_spd_cap_decelaration)
	else: speed = move_toward(speed, 0, gnd_acceleration)
	
	velocity = basis * (Vector3(0,0,speed) * Vector3.FORWARD)
	
	if not GroundRay.is_colliding() or direction_x.dot(Quaternion.IDENTITY) != 1.0:
		velocity.y += get_gravity().y
	
	universal_rotation()
	
	global_transform.basis = Basis((direction_x * direction).normalized())
	
	##Half States
	
	var g_actions = Anim.get("parameters/Rolling/GroundActions/blend_amount")
	
	Anim.set("parameters/Rolling/GroundActions/blend_amount",move_toward(g_actions,float(Input.is_action_pressed("spray_boost") and paint_weapon.GroundUse())-float(Input.is_action_pressed("fast_fall")),0.1))
	
	#if Input.is_action_pressed("fast_fall"): Anim.set("parameters/conditions/FastFall", true)
	#else: Anim.set("parameters/conditions/FastFall", false)
	#
	#if Input.is_action_pressed("spray_boost") and paint_weapon.GroundUse():
		#Anim.set("parameters/conditions/GroundUse", true)
	#else:
		#Anim.set("parameters/conditions/GroundUse", false)
	
	##Change States
	if not GroundRay.is_colliding() or direction_x.dot(Quaternion.IDENTITY) < 0.8:
		state = "Falling"

	# Handle jump.
	if Input.is_action_just_pressed("jump") and GroundRay.is_colliding():
		state = "Jumping"
	
	if !input_dir and velocity.is_zero_approx():
		state = "SkateIdle"
	

func Falling():
	if (velocity*speed).normalized()!=Vector3.ZERO:
		air_direction = Basis.looking_at((velocity*speed).normalized(),Vector3.UP).get_rotation_quaternion()
	
	direction = direction.slerp(Quaternion(Vector3.UP,input_cam_dir.angle()).normalized(),1/max(speed,10))
	
	global_transform.basis = Basis((direction_x * direction).normalized())
	
	velocity.y += get_gravity().y * delta * g_multiplier
	
	##To States
	if Input.is_action_pressed("jump") and GroundRay.is_colliding() and direction_x!=Quaternion.IDENTITY:
		last_wall_normal = GroundRay.get_collision_normal()
		velocity+=last_wall_normal*(speed/200)
	
	if velocity.y<0:
		g_multiplier = 2
	
	if Input.is_action_pressed("spray_boost") and paint_weapon.AirUse():
		Anim.set("parameters/conditions/AirUse", true)
	else:
		Anim.set("parameters/conditions/AirUse", false)
	
	if Input.is_action_pressed("fast_fall"):
		g_multiplier = 4
		Anim.set("parameters/conditions/FastFall", true)
	else:
		Anim.set("parameters/conditions/FastFall", false)
	
	if GroundRay.is_colliding() and velocity.y<0:
		## compare rotation and direction quats
		## to big of a change go fakie
		if rad_to_deg(air_direction.angle_to(quaternion))>140:
			speed=-speed
			state = "Skating"
		if rad_to_deg(air_direction.angle_to(quaternion))<60:
			state = "Skating"
		else:
			state = "Skating"
	
	universal_rotation()

func Skid():
	universal_rotation()
	
	global_transform.basis = Basis((direction_x * direction).normalized())
	
	velocity.x = move_toward(velocity.x, 0, gnd_decelaration)
	velocity.z = move_toward(velocity.z, 0, gnd_decelaration)
	velocity.y = 0
	
	
	if velocity.is_zero_approx():
		state = "Skating"

func is_on_ground():
	return Coll.get_overlapping_bodies()

func collision_custom_code():
	Coll.global_position = position + velocity.normalized()*0.1

func universal_rotation():
	if input_dir.length()>0.5:
		direction = direction.slerp(Quaternion(Vector3.UP,input_cam_dir.angle()).normalized(),1/max(abs(speed),10))
	
	#Rotate with is_on_wall normals but just after like a direction rotation
	AlignFloorRay.position = position
	if !is_on_ground():
		if AlignFloorRay.is_colliding():
			if AlignFloorRay.get_collision_normal() == Vector3.UP:
				direction_x = direction_x.slerp(Quaternion.IDENTITY,0.1)
	else:
		direction_x = direction_x.slerp(Quaternion.IDENTITY,0.1)
		if get_wall_normal() != Vector3.ZERO and Quaternion(Vector3.UP,get_wall_normal()).angle_to(direction_x)<1.5:
			var wall_alignment = Quaternion(Vector3.UP, get_wall_normal())
			if direction_x != wall_alignment and !Input.is_action_pressed("grind"):
				velocity+=GroundRay.get_collision_normal()
			elif Input.is_action_pressed("grind"):
				velocity-=GroundRay.get_collision_normal()*2
			direction_x = wall_alignment

func _physics_process(_delta: float) -> void:
	collision_custom_code()
	
	input_dir = Input.get_vector("left","right","down","up").rotated(+PI / 2)
	
	# Input data rotated for camera 
	input_cam_dir = input_dir.rotated((Camera.rotation.y+PI))
	
	
	##DEBUG
	#$"../UI/Debug/Label".text = str(state) + "\n" + previous_state + "\nspeed" + str(speed) + "\nvely" + str(velocity.y) + "\n" + str(g_multiplier) + "\n" + str((rotation.x))
	
	delta = _delta
	
	match state: 
		"SkateIdle":
			SkateIdle()
		"Skating":
			Skating()
		"Falling":
			Falling()
		"Skid":
			Skid()
	
	paint_weapon.fastfall = Input.is_action_pressed("fast_fall")
	paint_weapon.jump = Input.is_action_pressed("jump")
	paint_weapon.spray_button = Input.is_action_pressed("spray_boost")
	paint_weapon.input_dir = input_dir
	paint_weapon.input_cam_dir = input_cam_dir
	paint_weapon.item_process(delta)
	
	movement_ride.fastfall = Input.is_action_pressed("fast_fall")
	movement_ride.jump = Input.is_action_pressed("jump")
	movement_ride.spray_button = Input.is_action_pressed("spray_boost")
	movement_ride.input_dir = input_dir
	movement_ride.input_cam_dir = input_cam_dir
	movement_ride.ride_process(delta)
	
	move_and_slide()


func _on_custom_coll_area_entered(area: Area3D) -> void:
	if area.name == "DeathZone":
		get_tree().reload_current_scene()
