extends MultiplayerSpawner


# Called when the node enters the scene tree for the first time.
func _enter_tree() -> void:
	set_multiplayer_authority($"../Network/Character".player)#multiplayer.multiplayer_peer.get_unique_id())#$"../Network/Character".player)
