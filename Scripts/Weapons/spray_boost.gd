extends PaintWeapon

var spray_boost := 2.0

#inputs
var fastfall = false
var jump = false
var spray_button = false
var input_dir : Vector2
var input_cam_dir : Vector2

@onready
var SprayBoostMeter := $UI/SprayMeter
@onready
var Character : NewCharacter = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SprayBoost.reparent($"../../Character/Character/Body/RightArm/LowerArm4/Hand4/SprayBoost",false)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func item_process(delta: float) -> void:
	##Meter and Recharging Boost
	SprayBoostMeter.set_point_position(1,Vector2(0,spray_boost*-100))
	if spray_boost<=2:
		if !spray_button:
				spray_boost += 0.01
		#if fastfall == true:
			#spray_boost += 0.01
	elif spray_boost>2:
		spray_boost=2
	
	#position = $"../../Character/Character/Body/RightArm/LowerArm4/Hand4/SprayBoost".global_position

func AirMovement():
	pass

func AirUse():
	if spray_boost<=0:
		return false
	
	spray_boost -= 0.02
	
	$GPUParticles3D.emitting = true
	
	Character.velocity += Vector3(input_cam_dir.x,0,-input_cam_dir.y).rotated(Vector3.UP,90)*0.3
	
	if Character.speed<24:
		Character.speed += 1
	
	target_position = Vector3(0,-4,0)
	return _Graffitate()

func GroundUse():
	if spray_boost<=0:
		return false
		
	spray_boost -= 0.01
	
	$GPUParticles3D.emitting = true
	
	if Character.speed<24:
		Character.speed += 1
	
	target_position = Vector3(0,-2,0)
	return _Graffitate()
