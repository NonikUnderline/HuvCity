extends RayCast3D

class_name PaintWeapon

var LastGraffiti : GraffitiArt

const graffiti_scene := preload("res://Scenes/graffiti.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _Graffitate():
	if !is_colliding():
		return true
	
	if LastGraffiti != null and (LastGraffiti.global_position - global_position).length()<4.5:
		return true
	
	$PaintTimer.start()
	
	var new_graffiti := graffiti_scene.instantiate()
	$"../../../".add_child(new_graffiti,true)
	LastGraffiti = new_graffiti
	new_graffiti.position = position
	
	new_graffiti.visible = true
	new_graffiti.position = get_collision_point()
	if get_collision_normal() != Vector3.UP:
		new_graffiti.look_at(new_graffiti.position-get_collision_normal(),Vector3.UP)
		new_graffiti.rotate_object_local(Vector3(1,0,0),PI/2)
	
	new_graffiti.quaternion = new_graffiti.quaternion * Quaternion(Vector3(0,1,0),randf()*2*PI)
	
	return true
