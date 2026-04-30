extends CanvasLayer

@onready var label = $PanelContainer/MarginContainer/Label
@onready var box = $PanelContainer

func _ready():
	box.hide() # 初始隐藏
	GameEvents.show_tooltip.connect(_display)
	GameEvents.hide_tooltip.connect(_hide)

func _process(_delta):
	if box.visible:
		# 让对话框跟着鼠标坐标走，并加一点偏移量防止挡住鼠标
		box.global_position = box.get_global_mouse_position() + Vector2(20, 20)

func _display(text):
	label.text = text
	box.show()

func _hide():
	box.hide()
