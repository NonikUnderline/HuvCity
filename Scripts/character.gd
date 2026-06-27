extends CharacterBody3D


@export
var top_ground_speed : float = 25
@export
var jump_force : float = 6
@export
var ground_acceleration : float = 4
@export
var ground_decelaration : float = 1
@export
var skid_decelaration : float = 0.8
@export
var air_acceleration : float = 5
@export
var ground_turn_degrees : float = 5


#Variables for movement
var input_dir = Vector2.ZERO
var input_rot = Vector3.ZERO
var input_cam_dir = Vector2.ZERO
var forward_speed = 0.0

#State
var state = SkateIdle
# SkateIdle Skating Jumping

#Shared Delta beetween functions
var delta = 0.0

func SkateIdle():
	rotation.y = -input_cam_dir.angle()-deg_to_rad(90)
	
	if input_dir:
		state = Skating

func Skating():
	# On Air go to jumping
	if not is_on_floor():
		state=Jumping
	
	# Jump
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_force
	
	# If rotation is too different from where your velocity is taking you
	# Make the skate slide before having control again
	var velocity2d = Vector2(velocity.x,velocity.z)
	if input_dir and velocity:
		var velocity_angle = ((velocity2d*Vector2(-1,1)).rotated(PI/2).angle())
		if (abs(angle_difference(rotation.y,velocity_angle)))>1:
			state = SkateSkid
			return
	
	#If you rotate to far you loose speed
	# the input_cam_angle is basically getting input_cam_dir and correcting 
	# it to be in the same format as rotation.y
	var input_cam_angle = ((input_cam_dir*Vector2(-1,1)).rotated(PI/2).angle())
	if abs(angle_difference(rotation.y,input_cam_angle))>1:
		if forward_speed<0:
			forward_speed+=ground_decelaration
	
	# Speed is actually a float before being rotated and applied to
	# the velocity variable to be computed
	if abs(forward_speed)<=top_ground_speed:
		forward_speed -= abs(input_rot.y/ground_acceleration)
	if !input_dir:
		forward_speed = move_toward(forward_speed, 0, ground_decelaration)
	
	# Rotate through shortest path to where input_cam_dir points
	# (input_cam_dir being input dir rotated to cameras perspective)
	rotation.y = rotate_toward(rotation.y,-input_cam_dir.angle()-deg_to_rad(90),deg_to_rad(ground_turn_degrees))
	
	# Apply forward_speed in velocity rotated by rotation.y
	var speed = (transform.basis * Vector3(0, 0, forward_speed))
	velocity.x = speed.x
	velocity.z = speed.z
	
	if velocity.is_zero_approx():
		state = SkateIdle

func SkateSkid():
	# When sliding you can rotate
	rotation.y = rotate_toward(rotation.y,-input_cam_dir.angle()-deg_to_rad(90),deg_to_rad(15))
	
	# Slide till you stop
	velocity.x = move_toward(velocity.x,0,skid_decelaration)
	velocity.z = move_toward(velocity.z,0,skid_decelaration)
	
	if forward_speed<0:
			forward_speed+=ground_decelaration
	
	# if Speed Zero continue
	if velocity.is_zero_approx():
		state = Skating

func Jumping():
	# In mid air you can rotate freely
	rotation.y = rotate_toward(rotation.y,-input_cam_dir.angle()-deg_to_rad(90),deg_to_rad(8))
	
	# In mid air you can influence a little bit of your velocity
	if input_cam_dir:
		velocity += Vector3(input_cam_dir.x,0,input_cam_dir.y)/air_acceleration
	
	#gravity
	velocity += get_gravity() * delta
	
	# On floor go back to skating
	if is_on_floor():
		state = Skating

func _physics_process(v_delta: float) -> void:
	# Raw input data
	input_dir = Input.get_vector("Left", "Right", "Up", "Down")
	
	# Input data rotated for camera 
	input_cam_dir = input_dir.rotated($"../Camera3D".rotation.y)
	
	# Input Rotated inverse of player to get us
	# a vector going up and giving us left and right data
	input_rot = input_dir.rotated(rotation.y).rotated($"../Camera3D".rotation.y)
	#($"../Camera3D".transform.basis * transform.basis.inverse() * Vector3(input_dir.x, 0, input_dir.y))
	
	##DEBUG
	#$Line2D.set_point_position(1,(100*Vector2(cos(rotation.y), sin(rotation.y))))
	#$Line2D2.set_point_position(1,(100*((velocity2d*Vector2(-1,1)).rotated(PI/2).normalized())))
	
	delta = v_delta
	
	state.call()
	
	move_and_slide()
