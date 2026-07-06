extends CharacterBody3D

class_name NewCharacter

#Variables
#grounded
var gnd_max_speed = 22
var gnd_acceleration = 1
var gnd_spd_cap_decelaration = 0.2
var gnd_decelaration = 2
var gnd_rotation = 0.5

#air
var air_speed = 0.15
var jump_velocity = 9

#spray boost
var spray_max_speed = 27

#Movement
var speed = 0.0
var input_dir : Vector2
var input_cam_dir : Vector2
var input_rot : Vector2
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

#Refs
@onready
var Camera = $"../CameraGimbal"
@onready
var GroundRay = $Rays/Ground 
@onready
var Coll = $Colls/CustomColl
var CollOffset := Vector3(0,0,0)
@onready
var Anim = $CharacterNew/AnimationPlayer
@export
var paint_weapon : PaintWeapon

func set_state(new_state):
	if previous_state!=null:
		_exit_state(previous_state,new_state)
	if new_state!=null:
		_enter_state(new_state,previous_state)


func _enter_state(new_state, old_state):
	match new_state:
		"Jumping":
			Anim.play("Jump")
			
			velocity.y = jump_velocity
			
			g_multiplier = 1
			state = "Falling"
		"Skating":
			if old_state == "Falling":
				Anim.play("Land")
				
			if is_on_ground() and is_on_ground()[0].rotation!=Vector3.ZERO:
				speed += abs(velocity.y/18)
		"Falling":
			if GroundRay.get_collision_normal()!=Vector3.ZERO:
				velocity.y += abs(speed/18)

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

func Skating():
	##State Behavior
	if input_dir:
		if !Input.is_action_pressed("fast_fall"):
			var max_speed = gnd_max_speed
			var decelaration = gnd_acceleration
			if speed>gnd_max_speed-0.1:
				decelaration = gnd_spd_cap_decelaration
			speed = move_toward(speed, max_speed, decelaration)
	else: speed = move_toward(speed, 0, gnd_acceleration)
	
	velocity = basis * (Vector3(0,0,speed) * Vector3.FORWARD)
	
	if not GroundRay.is_colliding() or direction_x.dot(Quaternion.IDENTITY) != 1.0:
		velocity.y += get_gravity().y
	
	universal_rotation()
	
	global_transform.basis = Basis((direction_x * direction).normalized())
	
	##Half States
	if Input.is_action_pressed("spray_boost"):
		paint_weapon.GroundUse()
	
	##Change States
	if not GroundRay.is_colliding() or direction_x.dot(Quaternion.IDENTITY) < 0.8:
		state = "Falling"

	# Handle jump.
	if Input.is_action_just_pressed("jump") and GroundRay.is_colliding():
		state = "Jumping"
	
	if !input_dir and velocity.is_zero_approx():
		state = "SkateIdle"
	

func Falling():
	air_direction = Basis.looking_at((velocity*speed).normalized(),Vector3.UP).get_rotation_quaternion()
	
	direction = direction.slerp(Quaternion(Vector3.UP,input_cam_dir.angle()).normalized(),6/max(speed,10))
	
	global_transform.basis = Basis((direction_x * direction).normalized())
	
	velocity.y += get_gravity().y * delta * g_multiplier
	
	##To States
	if is_on_ground():
		last_wall_normal = GroundRay.get_collision_normal()
	
	if Input.is_action_pressed("jump") and is_on_ground():
		velocity+=last_wall_normal*(speed/9)
	
	if velocity.y<0:
		g_multiplier = 2
	
	if Input.is_action_pressed("spray_boost"):
		paint_weapon.AirUse()
	
	if Input.is_action_pressed("fast_fall"):
		g_multiplier = 4
	
	if is_on_ground() and velocity.y<0:
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
		direction = direction.slerp(Quaternion(Vector3.UP,input_cam_dir.angle()).normalized(),6/max(abs(speed),10))
	
	#Rotate with is_on_wall normals but just after like a direction rotation
	if is_on_ground() and get_wall_normal() != Vector3.ZERO:
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
	
	# Input Straight Up with left and right data
	input_rot = input_cam_dir.rotated(rotation.y)
	
	##DEBUG
	$UI/Debug/Label.text = str(state) + "\n" + previous_state + "\nspeed" + str(speed) + "\nvely" + str(velocity.y) + "\n" + str(g_multiplier) + "\n" + str((rotation.x))
	
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
	
	move_and_slide()
