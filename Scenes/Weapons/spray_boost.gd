extends Node3D

class_name PaintWeapon


const graffiti_scene := preload("res://Scenes/graffiti.tscn")
var spray_boost := 2.0

#inputs
var fastfall = false
var jump = false
var spray_button = false
var input_dir : Vector2
var input_cam_dir : Vector2

var LastGraffiti : GraffitiArt

@onready
var SprayCast := $SprayCast
@onready
var GraffitiColl := $GraffitiColl
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
		if fastfall == true:
			spray_boost += 0.01
	
	##Positioning
	SprayCast.position = Character.position
	SprayCast.rotation = Character.rotation
	
	GraffitiColl.rotation = Character.rotation
	
	position = $"../../Character/Character/Body/RightArm/LowerArm4/Hand4/SprayBoost".global_position

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
	
	SprayCast.target_position = Vector3(0,-4,0)
	return Graffitate()

func GroundUse():
	if spray_boost<=0:
		return false
		
	spray_boost -= 0.01
	
	$GPUParticles3D.emitting = true
	
	if Character.speed<24:
		Character.speed += 1
	
	SprayCast.target_position = Vector3(0,-2,0)
	return Graffitate()

func Graffitate():
	if !SprayCast.is_colliding():
		return true
	
	#if GraffitiColl.has_overlapping_areas():#or SprayCast.get_collider().get_parent() is GraffitiArt:
	if LastGraffiti != null and (LastGraffiti.position - position).length()<4.5:
		return true
	
	$PaintTimer.start()
	
	var new_graffiti := graffiti_scene.instantiate()
	$"../../..".add_child(new_graffiti)
	LastGraffiti = new_graffiti
	new_graffiti.position = position
	
	new_graffiti.visible = true
	new_graffiti.position = SprayCast.get_collision_point()
	if SprayCast.get_collision_normal() != Vector3.UP:
		new_graffiti.look_at(new_graffiti.position-SprayCast.get_collision_normal(),Vector3.UP)
		new_graffiti.rotate_object_local(Vector3(1,0,0),PI/2)
	
	new_graffiti.quaternion = new_graffiti.quaternion * Quaternion(Vector3(0,1,0),randf()*2*PI)
	
	return true
