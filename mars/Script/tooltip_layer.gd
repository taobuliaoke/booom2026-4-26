extends CanvasLayer

@onready var label = $PanelContainer/MarginContainer/Label
@onready var box = $PanelContainer

func _ready():
	box.hide() 
	GameEvents.show_tooltip.connect(_display)
	GameEvents.hide_tooltip.connect(_hide)

func _process(_delta):
	if box.visible:
		# 1. 计算理想的目标位置
		var target_pos = box.get_global_mouse_position() + Vector2(20, 20)
		
		# 2. 获取 Tooltip 当前经过重新排版后、绝对精准的实时尺寸
		var box_size = box.size
		
		# 3. 设定屏幕边界
		var max_w = 1600
		var max_h = 900
		
		# 4. 边界 Clamp
		target_pos.x = clamp(target_pos.x, 0, max_w - box_size.x)
		target_pos.y = clamp(target_pos.y, 0, max_h - box_size.y)
		
		box.global_position = target_pos

func _display(text):
	# 1. 在看不见的情况下悄悄换文字，避免被旧坐标和旧拉伸矩阵污染
	box.hide()
	label.text = text
	
	# 2. 强行剥夺长文本遗留的所有尺寸缓存
	label.size = Vector2.ZERO
	box.size = Vector2.ZERO
	
	# 3. 核心：强制通知容器引擎立即在底层进行短文本脱胎换骨的“重新量体裁衣”
	box.queue_sort()
	
	# 4. 闪电般显示出来，这时候 _process 拿到的 box.size 就是完美的短文本宽度了！
	box.show()

func _hide():
	box.hide()
