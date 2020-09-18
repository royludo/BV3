extends Control


############## button logic ##############


func _on_singlePlayer_pressed():
	get_tree().change_scene("res://mainScene.tscn")


func _on_multiplayer_pressed():
	var previousVisibility : bool = $VBoxContainer2.visible
	$VBoxContainer2.set_visible(not previousVisibility)


func _on_localMulti_pressed():
	print("local multi")
	pass # Replace with function body.


func _on_onlineMulti_pressed():
	var previousVisibility : bool = $VBoxContainer3.visible
	$VBoxContainer3.set_visible(not previousVisibility)


func _on_host_pressed():
	print("hosting")
	
	var host = NetworkedMultiplayerENet.new()
	var res = host.create_server(51234, 2)
	if res != OK:
		print("Error creating server")
		return
	get_tree().set_network_peer(host)


func _on_join_pressed():
	print("joining")
	
	var host = NetworkedMultiplayerENet.new()
	#host.create_client("82.64.45.42", 51234)
	host.create_client("82.64.45.42", 51234)
	get_tree().set_network_peer(host)



############## network stuff ##############

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")

func _player_connected(id):
	print("Player connected to server with id"+str(id))
	Globals.otherPlayerId = id
	Globals.is_online_multi = true
	var game = preload("res://mainScene.tscn").instance()
	get_tree().change_scene("res://mainScene.tscn")
	#get_tree().get_root().add_child(game)
	#hide()
	


