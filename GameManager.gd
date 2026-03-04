extends Node

var player_group: String = "unknown"

func _ready():
	if OS.has_feature("web"):
		var js_group = JavaScriptBridge.eval("localStorage.getItem('ab-group');")
		if js_group != null:
			player_group = js_group
		else:
			player_group = "A"
			print("This group A, is assigned by default cause no ab-group in localstorage")
	else:
		player_group = "A"
		print("This group A, is assigned by default cause no ab-group in localstorage, and you are not in web")
	
	print("Current Player Group: ", player_group)
	
	_sync_to_talo()

func _sync_to_talo():
	var props = { "ab-group": player_group }
	
	if has_node("/root/Talo"):
		var current_id = Talo.identity.get_id()
		Talo.identity.identify(current_id, props)
		print("Talo Sync Success: ", player_group, "player id =", current_id)
	else:
		push_warning("Talo Autoload not found!")
