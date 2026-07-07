extends Node3D

class_name GraffitiArt

var graffiti_finished := false

@export
var graffiti_paint_time := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$PaintTimer.wait_time = graffiti_paint_time
	$PaintTimer.start()
	$Art.albedo_mix = 0.0
	$Art.size = Vector3(7,2,7)
	$"../UI/Label".text = str(int($"../UI/Label".text)+1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Art.albedo_mix = move_toward($Art.albedo_mix,1,0.05)
	$Art.size.x = move_toward($Art.size.x,5,0.1)
	$Art.size.z = move_toward($Art.size.z,5,0.1)

func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	$EmitTimer.wait_time = 0.3
	$EmitTimer.start()
	graffiti_finished = true
	if $HurtBox.has_overlapping_bodies():
		for i in $HurtBox.get_overlapping_bodies():
			if i is NewCharacter:
				i.speed /= 2

func _on_emit_timer_timeout() -> void:
	$GPUParticles3D.emitting = false


func _on_other_graffiti_area_entered(area: Area3D) -> void:
	if area.get_parent() is GraffitiArt:
		var Gart : GraffitiArt = area.get_parent()
		if Gart.graffiti_finished:
			if Gart.get_index() < get_index():
				Gart.queue_free()
				$"../UI/Label".text = str(int($"../UI/Label".text)-1)
			else:
				queue_free()
				$"../UI/Label".text = str(int($"../UI/Label".text)-1)
	
