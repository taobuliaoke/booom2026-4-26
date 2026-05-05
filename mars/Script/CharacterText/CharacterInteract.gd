extends Area2D

# 这里的 word_name 可以作为角色的 ID，用来提取对应的文本和道具
@export var character_id: String = "沈慧心"
# 引用你想要弹出的 UI 界面（文本框和道具展示框的组合体）

@export var ui_pos_node: Marker2D #在编辑器离把刚才的marker2d拖进来

func _ready():
	#找到碰撞体并让它的形状资源变成“独有”的
	if has_node('CollisionShape2D'):
		var col = $CollisionShape2D
		if col.shape:
			#这行代码等同于编辑器里把Make unique点上
			col.shape = col.shape.duplicate()
			
	input_pickable = true # 必须开启，否则点不到
	# 监听对话框关闭的信号（假设你有关闭信号，或者监听状态改变）
	GameEvents.ui_closed_refresh_hover.connect(_on_ui_refresh)
	mouse_entered.connect(_on_mouse_entered) # 变小手
	mouse_exited.connect(_on_mouse_exited) # 恢复
	# 同样加入拾取检查组
	add_to_group("clue_items")
	check_status()

func _on_mouse_entered():
	if GameEvents.is_in_dialogue:return
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	#在通知显示新文本前，先通知全局UI把旧的Tooltip清空
	GameEvents.emit_signal('hide_tooltip')
	
	# 统一从 item_descriptions 读取 tooltip
	var desc = GameData.item_descriptions.get(character_id, "一个神秘的人")
	GameEvents.emit_signal("show_tooltip", desc)
	
func _on_mouse_exited():
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	GameEvents.emit_signal("hide_tooltip")
	
func _input_event(_viewport, event, _shape_idx):
	# 如果点的是左键
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_interact()


func _interact():
	var data = GameData.character_data.get(character_id, {})
	if data.is_empty(): return
	if GameEvents.is_in_dialogue:return
	print("弹出对话")
	var final_pos: Vector2
	if ui_pos_node:
		# 核心：将 Marker2D 的世界坐标转换为 UI 所在的屏幕画布坐标
		final_pos = ui_pos_node.get_global_transform_with_canvas().origin
		
	else:
		# 如果没给 Marker2D，则默认使用鼠标位置（作为备份）
		final_pos = get_viewport().get_mouse_position()
		
		# 发出信号，传递正确的画布位置
	GameEvents.emit_signal("request_character_dialog", character_id, final_pos)
	
	# 在执行任何点击逻辑前，先让 Tooltip 闭嘴,同时恢复鼠标样式
	GameEvents.emit_signal("hide_tooltip")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	# 从 GameData 获取该角色的配置

	var word = data.get("collectible_word", "")
	if word != "" and not GameEvents.clues_registry.get(word, false):
		GameEvents.add_word(word) # 拾取词条
		get_tree().call_group("clue_items", "check_status")
	
	#发出信号，传递目标坐标
	#GameEvents.emit_signal("request_character_dialog", character_id)
	GameEvents.is_in_dialogue = true
	
#关闭对话ui之后刷新鼠标样式
func _on_ui_refresh():
	# 如果当前已经不在对话中了，才进行恢复检查
	if GameEvents.is_in_dialogue:
		return
	
	# 获取当前的鼠标全局位置
	var mouse_pos = get_global_mouse_position()
	
	# 物理检测：检查鼠标点下有哪些碰撞体
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true # 必须开启，因为我们是 Area2D
	
	var results = space_state.intersect_point(query)
	
	# 遍历结果，看鼠标是不是还指着我
	for dict in results:
		if dict.collider == self:
			# 只要鼠标还在我身上，就手动触发“进入”逻辑
			# 这样小手图标和 Tooltip 都会立刻回来
			_on_mouse_entered() 
			break

func check_status():
	# 角色通常不会在拾取后消失，但你可以让他的 Tooltip 改变或者变灰[cite: 12]
	pass
