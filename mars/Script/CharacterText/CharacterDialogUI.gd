extends Control

#导出路径
@onready var dialog_label = $MyCustomLabel
@onready var item_box = $ItemBox
@onready var dialog_box = $Itempreview
@onready var container = $ItemBox/HFlowContainer

func _ready():
	# 如果正在看信，对话框就当没看见点击，不要自己缩回去
	if not visible or GameEvents.is_sub_ui_open:
		return
	GameEvents.request_character_dialog.connect(show_content)
	# 重点：订阅 GameEvents 的“电报”，只要有人点屏幕，我就去检查
	GameEvents.global_clicked.connect(_on_global_clicked)

# 这个 id 是从 NPC 脚本传过来的
func show_content(id: String):

	#从GameDate里读Character_date
	visible = true
	var data= GameData.character_data.get(id,{})
	
	# 1. 每次显示前，清空旧的道具图标
	for child in container.get_children():
		child.queue_free()
	
	if data.is_empty():
		dialog_label.text = '……'
		item_box.hide()
		return
	#填入自定义文本内容
	dialog_label.text = data.get('dialog','')
	
	# 获取道具数组
	var items_array = data.get("items", [])
	if items_array != []:
		for item_info in items_array:
			add_new_item(item_info)
		item_box.show()
	else:
		item_box.hide()
		 
func _on_global_clicked(event: InputEventMouseButton):
	# 如果我本来就没出来，那就不用理会
	if GameEvents.is_sub_ui_open:
		return
	if not visible:
		return
	var dialog_rect = dialog_box.get_global_rect()
	var item_rect = item_box.get_global_rect()
	# 【核心逻辑】
	# get_global_rect() 获取这个 UI 面板在屏幕上的矩形区域
	# has_point(点击位置) 判断你点的地方在不在这个矩形里
	if item_box.visible:
		if dialog_rect.has_point(event.global_position) or item_rect.has_point(event.global_position):
			return
	if dialog_rect.has_point(event.global_position):
		return
	
	print("点到 UI 外面了，收起面板")
	hide()
	await get_tree().process_frame
	GameEvents.is_in_dialogue = false
	# 收起面板
	
func add_new_item(info: Dictionary):
	var rect = TextureRect.new()
	rect.texture = load(info.get("path", "")) # 从字典获取路径[cite: 16]
	rect.custom_minimum_size = Vector2(80, 80)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	
	# 根据数据决定交互逻辑
	if info.get("can_interact", false):
		rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		rect.mouse_filter = Control.MOUSE_FILTER_STOP # 允许拦截鼠标[cite: 13]
		
		# 绑定点击信号
		rect.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				# 发送详情内容给次级
				GameEvents.emit_signal("request_item_detail", info.get("content", ""))
	)
	else:
		# 不可交互的道具，鼠标穿透，不给反馈
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE     
	$ItemBox/HFlowContainer.add_child(rect)
	
