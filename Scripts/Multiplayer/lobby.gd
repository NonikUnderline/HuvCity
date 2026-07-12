extends Node

const PORT = 4433

func _ready():
	# Start paused.
	#get_tree().paused = true
	# You can save bandwidth by disabling server relay and peer notifications.
	multiplayer.server_relay = false

	# Automatically start the server in headless mode.
	if DisplayServer.get_name() == "headless":
		print("Automatically starting dedicated server.")
		_on_host_pressed.call_deferred()
	
	# We only need to spawn players on the server.
	if not multiplayer.is_server():
		return
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	# Spawn already connected players.
	for id in multiplayer.get_peers():
		add_player(id)
	
	# Spawn the local player unless this is a dedicated server export.
	if not OS.has_feature("dedicated_server"):
		add_player(1)


func add_player(id: int):
	var character = preload("res://Models/CharacterNew/CharacterNew.tscn").instantiate()
	# Set player id.
	character.player = id
	# Randomize character position.
	character.position = Vector3(75,12,-25)
	character.name = str(id)
	$Level/Sandbox/Network.add_child(character, true)


func del_player(id: int):
	if not $Level/Sandbox/Network.has_node(str(id)):
		return
	$Level/Sandbox/Network.get_node(str(id)).queue_free()


func _on_host_pressed():
	# Start as server.
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer server.")
		return
	multiplayer.multiplayer_peer = peer
	start_game()


func _on_connect_pressed():
	# Start as client.
	var txt : String = $UI/Net/Remote.text
	if txt == "":
		OS.alert("Need a remote to connect to.")
		return
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(txt, PORT)
	if peer.get_connection_status() == MultiplayerPeer.CONNECTION_DISCONNECTED:
		OS.alert("Failed to start multiplayer client.")
		return
	multiplayer.multiplayer_peer = peer
	start_game()


func start_game():
	# Hide the UI and unpause to start the game.
	$UI.hide()
	multiplayer.server_relay = true
	#get_tree().paused = false
