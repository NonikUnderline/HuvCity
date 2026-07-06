extends Node3D

class_name Graffiti

@export
var graffiti_paint_time := 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = graffiti_paint_time
	$Timer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_timer_timeout() -> void:
	$GPUParticles3D.emitting = true
	if $HurtBox.has_overlapping_bodies():
		for i in $HurtBox.get_overlapping_bodies():
			if i is NewCharacter:
				i.speed /= 2
