extends Control

onready var build_menu = get_node("../..")
# Called when the node enters the scene tree for the first time.
func _ready():
	connect("gui_input", build_menu, "on_icon_input_event", [self])


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
