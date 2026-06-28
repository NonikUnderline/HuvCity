extends CharacterBody3D


var gnd_speed = 14
var gnd_acceleration = 0.5
var gnd_decelaration = 0.4
var air_speed = 7
var air_acceleration = 0.1
var skid_decelaration = 0.8

var jump_force : float = 6

var coyote_time = 20

#Variables for movement
var input_dir = Vector2.ZERO
var input_rot = Vector3.ZERO
var input_cam_dir = Vector2.ZERO
var direction = 0.0
var speed = 0.0

var coyote_timer = coyote_time

#State
var state = SkateIdle
# SkateIdle Skating Jumping

#Shared Delta beetween functions
var delta = 0.0

func SkateIdle():
	if input_dir.length()>0.5:
		rotation.y = rotation_angle(input_cam_dir.angle())
	
	velocity.x = move_toward(velocity.x,0,gnd_decelaration)
	velocity.z = move_toward(velocity.z,0,gnd_decelaration)
	
	if not is_on_floor():
		state=Jumping
	
	if input_dir:
		state = Skating

func Skating():
	# On Air go to jumping
	if not is_on_floor():
		state=Jumping
	
	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force
	
	rotation.y=rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),PI/22.5)
	direction = rotation_angle(rotation.y)
	
	speed = move_toward(speed,-input_rot.y*gnd_speed,gnd_acceleration)
	velocity.x = cos(direction)*speed
	velocity.z = sin(direction)*speed
	
	if input_dir.length()<0.5:
		state=SkateIdle
		speed=0

func Skid():
	velocity.x = move_toward(velocity.x,0,skid_decelaration)
	velocity.z = move_toward(velocity.z,0,skid_decelaration)
	speed = move_toward(speed,0,skid_decelaration)
	
	direction = rotate_toward(direction,rotation_angle(rotation.y),PI/30)
	
	if not is_on_floor():
		state=Jumping
	
	if abs(angle_difference(direction,rotation_angle(rotation.y)))<0.2:
		state=Skating
	
	if !input_dir or velocity.is_zero_approx():
		state = SkateIdle

func Jumping():
	if coyote_timer>0:
		coyote_timer-=1
		if Input.is_action_just_pressed("Jump"):
			velocity.y = jump_force
			coyote_timer=0
	
	rotation.y = rotation_angle(input_cam_dir.angle())
	
	#gravity
	velocity += get_gravity() * delta
	if (Input.is_action_pressed("QuickFall")):
		velocity += get_gravity() * delta * 3
	
	velocity.x = move_toward(velocity.x,input_dir.x*air_speed,air_acceleration)
	velocity.z = move_toward(velocity.z,input_dir.y*air_speed,air_acceleration)
	speed = velocity.length()
	
	# On floor go back to skating
	if is_on_floor():
		coyote_timer = coyote_time
		if abs(angle_difference(direction,rotation_angle(rotation.y)))<1.5:
			state = Skating
		else:
			speed=0
			state = Skid

func _physics_process(v_delta: float) -> void:
	# Raw input data
	input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	
	# Input data rotated for camera 
	input_cam_dir = input_dir.rotated($"../Camera3D".rotation.y)
	
	# Input Straight Up with left and right data
	input_rot = input_cam_dir.rotated(rotation.y)
	
	##DEBUG
	$Line2D.set_point_position(1,(100*Vector2(cos(rotation_angle(rotation.y)),sin(rotation_angle(rotation.y)))))
	$Line2D2.set_point_position(1,(100*Vector2(cos(direction),sin(direction))))
	
	delta = v_delta
	
	state.call()
	
	move_and_slide()

# Function for converting beetween rotation on the 3D and rotation as vector2 angles
func rotation_angle(angle : float):
	return -angle-PI/2
