extends Node

var player_group: String = "unknown"

func _ready():
	if OS.has_feature("web"):
		var js_group = JavaScriptBridge.eval("localStorage.getItem('ab-group');")
		if js_group != null:
			player_group = js_group
		else:
			player_group = "A"
	else:
		player_group = "A"
	
	print("Current Player Group: ", player_group)
	
	_sync_to_talo()

func _sync_to_talo():
	var props = { "ab-group": player_group }
	
	if has_node("/root/Talo"):
		var current_id = Talo.identity.get_id()
		Talo.identity.identify(current_id, props)
		print("Talo Sync Success: ", player_group)
	else:
		push_warning("Talo Autoload not found!")
