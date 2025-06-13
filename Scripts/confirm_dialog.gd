extends Node

@export var dialogTitle : String
@export var dialogContent : String

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Panel/DialogTitle.text = dialogTitle
	$Panel/DialogContent.text = dialogContent
	pass
