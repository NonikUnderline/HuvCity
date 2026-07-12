extends Node3D

class_name MovementRide


const graffiti_scene := preload("res://Scenes/graffiti.tscn")

#inputs
var fastfall = false
var jump = false
var spray_button = false
var input_dir : Vector2
var input_cam_dir : Vector2

#rotation Y 
var total_rotation = 0.0
var last_y_rotation = 0.0 

var direction_ground : Quaternion

var LastGraffiti : GraffitiArt

@onready
var SprayCast := $SprayCast
@onready
var GraffitiColl := $GraffitiColl

@onready
var Character : NewCharacter = $"../.."
@onready
var TrickLabel := $UI/Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	last_y_rotation = Character.rotation.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func ride_process(delta: float) -> void:
	if Character.state == "Falling":
		var current_y_rotation = direction_ground.angle_to(Character.direction) * sign(input_cam_dir.rotated(-Character.rotation.y).angle())
		
		# Calculate the difference between the current frame and the last frame
		var delta_rotation = current_y_rotation - last_y_rotation
		
		direction_ground = Character.direction
		# Handle wrap-around at PI and -PI
		#if current_y_rotation > PI*0.5:
			#delta_rotation += PI/2
		#elif delta_rotation >= PI/2:
			#delta_rotation -= PI
			
		total_rotation += current_y_rotation
		last_y_rotation = current_y_rotation
		
		if total_rotation>0: TrickLabel.text = "BackSide "
		else: TrickLabel.text = "FrontSide "
		TrickLabel.text += str(round((rad_to_deg(total_rotation))))
	else:
		direction_ground = Character.direction
		total_rotation = 0.0
		last_y_rotation = 0.0

func WhenLanding():
	if abs(total_rotation)>PI/2:
		Graffitate()

func Graffitate():
	if !SprayCast.is_colliding():
		return true
	
	#if GraffitiColl.has_overlapping_areas():#or SprayCast.get_collider().get_parent() is GraffitiArt:
	
	var new_graffiti := graffiti_scene.instantiate()
	$"../../..".add_child(new_graffiti,true)
	LastGraffiti = new_graffiti
	
	if abs(total_rotation)>TAU*3: total_rotation = TAU*3
	var graf_size = (abs(total_rotation)*10)/TAU
	
	
	Character.paint_weapon.spray_boost += abs((total_rotation*0.3)/TAU)
	Character.speed += abs((total_rotation*4)/TAU)
	
	new_graffiti.visible = true
	new_graffiti.start_size = Vector2(graf_size*0.8,graf_size*0.8)
	new_graffiti.painted_size = Vector2(graf_size,graf_size)
	new_graffiti.position = SprayCast.get_collision_point()
	if SprayCast.get_collision_normal() != Vector3.UP:
		new_graffiti.look_at(new_graffiti.position-SprayCast.get_collision_normal(),Vector3.UP)
		new_graffiti.rotate_object_local(Vector3(1,0,0),PI/2)
	
	new_graffiti.quaternion = new_graffiti.quaternion * Quaternion(Vector3(0,1,0),randf()*2*PI)
	
	return true
