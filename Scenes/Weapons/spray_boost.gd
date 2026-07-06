extends Node3D

class_name PaintWeapon


const graffiti_scene := preload("res://Scenes/graffiti.tscn")
var spray_boost := 2.0


@onready
var SprayCast = $SprayCast
@onready
var GraffitiColl = $GraffitiColl
@onready
var SprayBoostMeter = $UI/SprayMeter
@onready
var Character : NewCharacter = $"../.."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	SprayBoostMeter.set_point_position(1,Vector2(0,spray_boost*-100))
	if spray_boost<=2 and !Input.is_action_pressed("spray_boost"):
		spray_boost += 0.01
	
	SprayCast.position = Character.position
	SprayCast.rotation = Character.rotation

func AirMovement():
	pass

func AirUse():
	pass

func GroundUse():
	$GPUParticles3D.emitting = true
	
	spray_boost -= 0.01
	
	if Character.speed<27:
		Character.speed = 27
	
	if !SprayCast.is_colliding() or GraffitiColl.has_overlapping_areas():
		return
	
	var new_graffiti := graffiti_scene.instantiate()
	$"../../..".add_child(new_graffiti)
	new_graffiti.position = position
	
	new_graffiti.visible = true
	new_graffiti.position = SprayCast.get_collision_point()
	if SprayCast.get_collision_normal() != Vector3.UP:
		new_graffiti.look_at(new_graffiti.position+SprayCast.get_collision_normal(),Vector3.UP)
		new_graffiti.rotate_object_local(Vector3(1,0,0),PI/2)
	
	new_graffiti.rotation.y = randf()*2*PI
