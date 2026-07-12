extends Node3D

@onready
var character = $"../Network/"

var sensitivity = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var target_rotation : float
	
	for i in character.get_children():
		if i is NewCharacter:
			if i.player == multiplayer.get_unique_id():
				target_rotation = i.rotation.y
				position+=i.position-position
	
	rotate_y(angle_difference(rotation.y,target_rotation)/90)
	
	var cam_mov = Input.get_vector("cam_right", "cam_left", "cam_down", "cam_up")/sensitivity
	
	rotate_y(cam_mov.x)
	rotation.x += (cam_mov.y)
