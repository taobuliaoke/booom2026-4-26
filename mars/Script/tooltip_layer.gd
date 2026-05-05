extends CanvasLayer

@onready var label = $PanelContainer/MarginContainer/Label
@onready var box = $PanelContainer

func _ready():
	box.hide() 
	GameEvents.show_tooltip.connect(_display)
	GameEvents.hide_tooltip.connect(_hide)

func _process(_delta):
	if box.visible:

func _display(text):
	label.text = text
	box.show()
	box.reset_size()

func _hide():
	box.hide()
