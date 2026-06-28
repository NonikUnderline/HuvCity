extends CharacterBody3D


var gnd_speed = 14
var gnd_acceleration = 0.5
var gnd_decelaration = 0.4
var air_speed = 7
var air_acceleration = 0.1
var skid_decelaration = 0.5
var to_skid_ang_threshold = 1
var out_of_skid_ang_threshold = 0.1

var jump_force : float = 7

var coyote_time = 20

var spray_air_speed = 9
var spray_gnd_speed = 0.5
var turn_deg_penalty = 0.01
var gnd_skating_decelaration = 0.2

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
var state = SkateIdle
# SkateIdle Skating Jumping

#Shared Delta beetween functions
var delta = 0.0

#Nodes
@onready
var SprayParticles = $SprayParticles
@onready
var Camera = $"../CameraGimbal"
	

func SkateIdle():
	if input_dir.length()>0.5:
		rotation.y = rotation_angle(input_cam_dir.angle())
	
	velocity.x = move_toward(velocity.x,0,gnd_decelaration)
	velocity.z = move_toward(velocity.z,0,gnd_decelaration)
	
	if not is_on_floor():
		state=MidAir
	
	if input_dir:
		state = Skating
		$blockbench_export/AnimationPlayer.play("Push")

func Skating():
	# On Air go to jumping
	if not is_on_floor():
		state=MidAir
	
	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		$blockbench_export/AnimationPlayer.play("JumpOllie")
		if Input.is_action_pressed("fast_fall"):
			velocity.y += jump_force/2
	
	# Prep Jump
	if Input.is_action_just_pressed("fast_fall"):
		$blockbench_export/AnimationPlayer.play("PrepJump")
	
	#recharge Spray
	if spray_charge<2:
		spray_charge += 0.03
	
	#Rotation
	rotation.y=rotate_toward(rotation.y,rotation_angle(input_cam_dir.angle()),(PI/speed))
	direction = rotation_angle(rotation.y)
	
	#decelerate if you turn too much
	if abs(input_rot.x)>PI/180 and speed>0:
		speed-=rad_to_deg(abs(input_rot.x))*turn_deg_penalty
	
	#speed Direction
	if speed<=-input_rot.y*gnd_speed:
		speed = move_toward(speed,-input_rot.y*gnd_speed,gnd_acceleration)
	else:
		speed = move_toward(speed,-input_rot.y*gnd_speed,gnd_skating_decelaration)
	velocity.x = cos(direction)*(speed)
	velocity.z = sin(direction)*(speed)
	
	#Ground SPray Boosting
	if Input.is_action_just_pressed("spray_boost"):
		$blockbench_export/AnimationPlayer.play("SprayBoost")
	if Input.is_action_just_released("spray_boost"):
		$blockbench_export/AnimationPlayer.play("Land")
		SprayParticles.emitting = false
	if Input.is_action_pressed("spray_boost") and spray_charge>0 and !spray_overheat:
		speed+=spray_gnd_speed
		spray_charge-=0.05
		SprayParticles.process_material.direction = Vector3(0,0.5,1)
		SprayParticles.emitting = true
	
	#Stop Skating
	if input_dir.length()<0.5:
		state=SkateIdle
		$blockbench_export/AnimationPlayer.play("Idle")
		speed=0

#func SprayBoost():
	#

func Skid():
	#velocity go to zero
	if !$EdgeRaycast.is_colliding():
		velocity.x =0
		velocity.z = 0
	velocity.x = move_toward(velocity.x,0,skid_decelaration)
	velocity.z = move_toward(velocity.z,0,skid_decelaration)
	speed = move_toward(speed,0,skid_decelaration)
	
	#rotate speed direction to your facing direction
	direction = rotate_toward(direction,rotation_angle(rotation.y),PI/(speed*1.5))
	
	if not is_on_floor():
		state=MidAir
	
	#if direction and rotation align go to skating
	if abs(angle_difference(direction,rotation_angle(rotation.y)))<out_of_skid_ang_threshold:
		$blockbench_export/AnimationPlayer.play("Push")
		state=Skating
	
	if !input_dir or is_zero_approx(speed):
		$blockbench_export/AnimationPlayer.play("Idle")
		state = SkateIdle

func MidAir():
	#Jump if Coyote Time
	if coyote_timer>0:
		coyote_timer-=1
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_force
			coyote_timer=0
			return
	
	#Rotate to input
	rotation.y = rotation_angle(input_cam_dir.angle())
	
	#gravity and fast fall
	velocity += get_gravity() * delta
	if (Input.is_action_pressed("fast_fall")):
		velocity += get_gravity() * delta * 3
	#animation
	if (Input.is_action_just_pressed("fast_fall")):
		$blockbench_export/AnimationPlayer.play("FastFall")
	if (Input.is_action_just_released("fast_fall")):
		$blockbench_export/AnimationPlayer.play_backwards("FastFall")
	
	var velocity2d = Vector2(velocity.x,velocity.z)
	
	# Little movement midair
	if abs(input_cam_dir.angle()-velocity2d.angle())>0.2:
		velocity.x = move_toward(velocity.x,input_cam_dir.x*air_speed,air_acceleration)
		velocity.z = move_toward(velocity.z,input_cam_dir.y*air_speed,air_acceleration)
	speed = velocity.length()
	
	# Huv It
	if Input.is_action_just_pressed("jump") and spray_charge>=1 and !spray_overheat:
		SprayParticles.process_material.direction = Vector3(0,-1,0)
		SprayParticles.emitting = true
		$blockbench_export/AnimationPlayer.play("Huv It")
		spray_charge-=1
		velocity.y = jump_force*1.5
	
	#Spray Boost
	if Input.is_action_just_pressed("spray_boost") and spray_charge>=1 and !spray_overheat:
		SprayParticles.process_material.direction = Vector3(0,0.5,1)
		SprayParticles.emitting = true
		$blockbench_export/AnimationPlayer.play("SprayBoost")
		spray_charge-=1
		velocity.x += input_cam_dir.x*spray_air_speed
		velocity.z += input_cam_dir.y*spray_air_speed
		velocity.y = jump_force/2
		#state = SprayBoost
	
	if is_on_floor():
		coyote_timer = coyote_time
		# On floor go back to skating or to skid if you're not rotated correctly
		if abs(angle_difference(direction,rotation_angle(rotation.y)))<to_skid_ang_threshold:
			$blockbench_export/AnimationPlayer.play("Land")
			state = Skating
		else:
			$blockbench_export/AnimationPlayer.play("SkidLand")
			state = Skid

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
	
	##DEBUG
	$Line2D.set_point_position(1,(100*input_rot))
	$Line2D2.set_point_position(1,(100*Vector2(cos(direction),sin(direction))))
	
	delta = v_delta
	
	state.call()
	
	move_and_slide()

# Function for converting beetween rotation on the 3D and rotation as vector2 angles
func rotation_angle(angle : float):
	return -angle-PI/2
