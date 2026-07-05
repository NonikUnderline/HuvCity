extends CharacterBody3D

class_name NewCharacter

#Variables
#grounded
var gnd_max_speed = 18
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
var speed = 15
var input_dir : Vector2
var input_cam_dir : Vector2
var input_rot : Vector2

#direction
var direction : Quaternion = Quaternion.IDENTITY
var direction_x : Quaternion = Quaternion.IDENTITY

var air_direction : Quaternion = Quaternion.IDENTITY

var g_multiplier = 1.0

#Graffiti
const graffiti_scene := preload("res://Scenes/graffiti.tscn")
var spray_boost := 2.0

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
var GroundRay = $Ground 
@onready
var Coll = $CustomColl
var CollOffset := Vector3(0,0,0)
@onready
var Anim = $CharacterNew/AnimationPlayer
@onready
var SprayBoostMeter = $UI/SprayMeter


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

func _init() -> void:
	motion_mode = MOTION_MODE_FLOATING
	floor_snap_length = 0.5

func _exit_state(old_state,new_state):
	match old_state:
		pass

func SkateIdle():
	velocity.x = move_toward(velocity.x, 0, gnd_decelaration)
	velocity.z = move_toward(velocity.z, 0, gnd_decelaration)
	speed = move_toward(speed, 0, gnd_decelaration)
	velocity.y = move_toward(velocity.y, 0, gnd_decelaration)
	
	if input_dir:
		state = "Skating"
	
	if Input.is_action_just_pressed("jump") and is_on_ground():
		state = "Jumping"

func Skating():
	##State Behavior
	if input_dir and is_on_ground():
		if !Input.is_action_pressed("fast_fall"):
			if speed>=0:
				if speed<gnd_max_speed:
					speed = move_toward(speed, gnd_max_speed, gnd_acceleration)
				else:
					speed = move_toward(speed, gnd_max_speed, gnd_spd_cap_decelaration)
			if Input.is_action_pressed("spray_boost") and spray_boost >= 0.1:
				speed = move_toward(speed, spray_max_speed, gnd_acceleration)
		
		velocity = basis * (Vector3(0,0,speed) * Vector3.FORWARD)
	
	velocity.y += get_gravity().y
	
	##Half States
	if Input.is_action_pressed("spray_boost") and spray_boost >= 0.1:
		Graffitate()
		spray_boost -= 0.01
	
	##Change States
	if not is_on_ground():
		state = "Falling"

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_ground():
		state = "Jumping"
		return
	
	if !input_dir:
		state = "SkateIdle"

func Falling():
	if (velocity*Vector3(speed,speed,speed))!=Vector3.ZERO:
		air_direction = Basis.looking_at((velocity*Vector3(speed,speed,speed)).normalized(),Vector3.UP).get_rotation_quaternion()
	
	direction = direction.slerp(Quaternion(Vector3.UP,input_cam_dir.angle()).normalized(),6/max(speed,10))
	
	velocity.y += get_gravity().y * delta * g_multiplier
	
	velocity += Vector3(input_cam_dir.x*air_speed,0,0).rotated(Vector3.RIGHT,rotation.x).rotated(Vector3.BACK,rotation.z)
	
	##To States
	if velocity.y<0:
		g_multiplier = 2
	
	if Input.is_action_pressed("spray_boost"):
		Graffitate()
	
	if Input.is_action_pressed("fast_fall"):
		g_multiplier = 4
	
	if is_on_ground() and velocity.y<0:
		if is_on_ground()[0].rotation!=Vector3.ZERO:
			speed += abs(velocity.y/7)
		## compare rotation and direction quats
		## to big of a change go fakie
		if rad_to_deg(air_direction.angle_to(quaternion))>120:
			speed=-speed
			state = "Skating"
		if rad_to_deg(air_direction.angle_to(quaternion))<40:
			state = "Skating"
		else:
			state = "SkateIdle"

func Graffitate():
	if !GroundRay.is_colliding() or $GraffitiColl.has_overlapping_areas():
		return
	
	var new_graffiti := graffiti_scene.instantiate()
	$"../".add_child(new_graffiti)
	new_graffiti.position = position
	
	new_graffiti.visible = true
	new_graffiti.position = GroundRay.get_collision_point()
	if GroundRay.get_collision_normal() != Vector3.UP:
		new_graffiti.look_at(new_graffiti.position+GroundRay.get_collision_normal(),Vector3.UP)
		new_graffiti.rotate_object_local(Vector3(1,0,0),PI/2)
	
	new_graffiti.rotation.y = randf()*2*PI


func is_on_ground():
	return Coll.get_overlapping_bodies()

func collision_custom_code():
	Coll.global_position = position + velocity.normalized()

func universal_rotation():
	if input_dir.length()>0.5:
		direction = direction.slerp(Quaternion(Vector3.UP,input_cam_dir.angle()).normalized(),6/max(abs(speed),10))
	
	#Rotate with is_on_wall normals but just after like a direction rotation
	if is_on_ground() and get_wall_normal() != Vector3.ZERO:
			var wall_alignment = Quaternion(Vector3.UP, get_wall_normal())
			if direction_x != wall_alignment:
				velocity+=GroundRay.get_collision_normal()
			direction_x = wall_alignment
	
	global_transform.basis = Basis((direction_x * direction).normalized())

func _physics_process(_delta: float) -> void:
	collision_custom_code()
	
	input_dir = Input.get_vector("left","right","down","up").rotated(+PI / 2)
	
	# Input data rotated for camera 
	input_cam_dir = input_dir.rotated((Camera.rotation.y+PI))
	
	# Input Straight Up with left and right data
	input_rot = input_cam_dir.rotated(rotation.y)
	
	SprayBoostMeter.set_point_position(1,Vector2(0,spray_boost*-100))
	if spray_boost<=2 and !Input.is_action_pressed("spray_boost"):
		spray_boost += 0.01
	
	##DEBUG
	$Debug/Label.text = str(state) + "\n" + previous_state + "\nspeed" + str(speed) + "\ngrav" + str(velocity.y) + "\n" + str(g_multiplier) + "\n" + str((rotation.x))
	
	delta = _delta
	
	universal_rotation()
	
	match state: 
		"SkateIdle":
			SkateIdle()
		"Skating":
			Skating()
		"Falling":
			Falling()
	
	move_and_slide()
