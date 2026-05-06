extends CanvasLayer

@onready var label = $PanelContainer/MarginContainer/Label
@onready var box = $PanelContainer

func _ready():
	box.hide() 
	GameEvents.show_tooltip.connect(_display)
	GameEvents.hide_tooltip.connect(_hide)

func _process(_delta):
	if box.visible:
		# 1. 计算理想的目标位置（鼠标位置 + 偏移量）
		var target_pos = box.get_global_mouse_position() + Vector2(20, 20)
		
		# 2. 获取 Tooltip 当前的实时尺寸
		var box_size = box.size
		
		# 3. 设定屏幕的限制边界 (1600, 900)
		var max_w = 1600
		var max_h = 900
		
		# 4. 限制 X 轴：左边界不能小于 0，右边界不能让 box 的右侧超过 1600
		target_pos.x = clamp(target_pos.x, 0, max_w - box_size.x)
		
		# 5. 限制 Y 轴：上边界不能小于 0，下边界不能让 box 的底部超过 900
		target_pos.y = clamp(target_pos.y, 0, max_h - box_size.y)
		
		# 6. 将最终修正后的安全坐标赋给 box
		box.global_position = target_pos

func _display(text):
	label.text = text
	box.show()
	# 核心：必须在显示时立即重置尺寸，否则上面 _process 获取到的 box_size 可能是旧文本的尺寸
	box.reset_size()

func _hide():
	box.hide()
