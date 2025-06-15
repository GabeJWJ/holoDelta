extends Node

@export var dialogTitle : String
@export var dialogContent : String

# signal when confirm button is clicked
signal confirmed

# signal when cancel button is clicked
signal cancelled
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# sets the title and content of dialog
	$Panel/DialogTitle.text = dialogTitle
	$Panel/DialogContent.text = dialogContent
	pass

func _on_yes_button_pressed() -> void:
	emit_signal("confirmed")

func _on_no_button_pressed() -> void:
	# close and also execute the cancel signal
	self.visible = false
	emit_signal("cancelled")
	
# simply disabling the yes button or not
func set_yes_button_disabled(state: bool):
	$Panel/YesButton.disabled = state
