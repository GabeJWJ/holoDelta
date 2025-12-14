extends LineEdit

# Code to forcibly show the android virtual keyboard when the line
# edit is focused. It should do this automatically. It doesn't though.
func _ready():
	if OS.has_feature("android"):
		focus_entered.connect(_on_focus)

func _on_focus():
	DisplayServer.virtual_keyboard_show(text)
