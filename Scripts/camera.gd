extends Node3D

@onready
var character = $"../Character"

var sensitivity = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position+=character.position-position
	
	var target_rotation = character.rotation.y
	
	#rotate_y(angle_difference(rotation.y,target_rotation)/90)
	
	var cam_mov = Input.get_vector("cam_right", "cam_left", "cam_down", "cam_up")/sensitivity
	
	rotate_y(cam_mov.x)
	rotation.x += (cam_mov.y)
