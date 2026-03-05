extends Node

var player_group: String = "unknown"

func _ready():
	var detected_group = "unknown"
	
	if OS.has_feature("web"):
		print("trying URL way to get our group")
		var current_url = JavaScriptBridge.eval("window.location.href")
		if "version-b" in current_url or "version_b" in current_url:
			detected_group = "B"
		elif "version-a" in current_url or "version_a" in current_url:
			detected_group = "A"
		
		if detected_group == "unknown":
			print("no idea which URL, try localStorage")
			var js_group = JavaScriptBridge.eval("localStorage.getItem('ab-group');")
			if js_group != null:
				detected_group = js_group
			else:
				detected_group = "A" 
				print("Group is A, because no idea which URL, and no idea what hack is localStorage")
	else:
		detected_group = "A" 

	player_group = detected_group
	print("Final Resolved Group: ", player_group)
