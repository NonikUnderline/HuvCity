extends Node3D

class_name GraffitiArt

var graffiti_finished := false

@export
var graffiti_art : Texture2D
@export
var graffiti_paint_time := 1.0
@export
var start_size : Vector2 = Vector2(7,7)
@export
var painted_size : Vector2 = Vector2(5,5)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PaintTimer.wait_time = graffiti_paint_time
	$PaintTimer.start()
	$Art.albedo_mix = 0.0
	$Art.size = Vector3(start_size.x,2,start_size.y)
	$"../../UI/Label".text = str(int($"../../UI/Label".text)+1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Art.albedo_mix = move_toward($Art.albedo_mix,1,0.05)
	$Art.size.x = lerp($Art.size.x,painted_size.x,0.1) #move_toward($Art.size.x,painted_size.x,0.1)
	$Art.size.z = lerp($Art.size.z,painted_size.y,0.1) #move_toward($Art.size.z,painted_size.y,0.1)

func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	$EmitTimer.wait_time = 0.3
	$EmitTimer.start()
	graffiti_finished = true
	if $HitBox.has_overlapping_bodies():
		for i in $HitBox.get_overlapping_bodies():
			if i is NewCharacter:
				i.speed /= 4
				i.velocity.y += 14
				i.state = "Falling"
				i.paint_weapon.spray_boost /= 2

func _on_emit_timer_timeout() -> void:
	$GPUParticles3D.emitting = false


func _on_other_graffiti_area_entered(area: Area3D) -> void:
	if area.get_parent() is GraffitiArt:
		var Gart : GraffitiArt = area.get_parent()
		if Gart.graffiti_finished:
			if Gart.get_index() < get_index():
				Gart.queue_free()
				$"../../UI/Label".text = str(int($"../../UI/Label".text)-1)
			else:
				queue_free()
				$"../../UI/Label".text = str(int($"../../UI/Label".text)-1)
	
