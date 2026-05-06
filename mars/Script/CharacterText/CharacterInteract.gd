extends Area2D

# 1. 变量定义
@export var character_id: String = ""
@export var ui_pos_node: Marker2D 

func _ready():
	if has_node('CollisionShape2D'):
		var col = $CollisionShape2D
		if col.shape:
			col.shape = col.shape.duplicate()
			
	input_pickable = true 
	GameEvents.ui_closed_refresh_hover.connect(_on_ui_refresh)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	add_to_group("clue_items")

# --- 2. 核心交互逻辑 (嫁接后的版本) ---
func _input_event(_viewport, event, _shape_idx):

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_interact()

func _interact():
	if GameEvents.is_sub_ui_open: return
	if GameEvents.is_in_dialogue: return
	var data = GameData.character_data.get(character_id, {})
	if data.is_empty() or GameEvents.is_in_dialogue: 
		return

	# 计算 UI 弹出位置 [这里的 final_pos 替代了你报错的 pos]
	var final_pos: Vector2
	if ui_pos_node:
		final_pos = ui_pos_node.get_global_transform_with_canvas().origin
	else:
		final_pos = get_viewport().get_mouse_position()
		
	# 发送信号给 UI 脚本 [这里的 character_id 替代了你报错的 cid]
	GameEvents.emit_signal("request_character_dialog", character_id, final_pos)
	
	# 清理状态
	GameEvents.emit_signal("hide_tooltip")
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# 角色身上可能附带的自动拾取逻辑 (可选)
	var word = data.get("collectible_word", "")
	if word != "" and not GameEvents.clues_registry.get(word, false):
		GameEvents.add_word(word)
		get_tree().call_group("clue_items", "check_status")

# --- 3. 辅助功能函数 ---

func _on_word_picked():
	if character_id == "" or GameEvents.clues_registry.get(character_id, false):
		return
		
	print("成功拾取文本词条: ", character_id)
	GameEvents.add_word(character_id)
	GameEvents.collect_clue(character_id)
	
	# 拾取效果：淡出并销毁该 Area2D
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.2)
	await tween.finished
	queue_free()

func _on_mouse_entered():
	if GameEvents.is_in_dialogue: return
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	var desc = GameData.item_descriptions.get(character_id, "一个神秘的人")
	GameEvents.emit_signal("show_tooltip", desc)
	
func _on_mouse_exited():
	if GameEvents.is_in_dialogue:return
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	GameEvents.emit_signal("hide_tooltip")

func _on_ui_refresh():
	if GameEvents.is_in_dialogue: return
	var mouse_pos = get_global_mouse_position()
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	var results = space_state.intersect_point(query)
	for dict in results:
		if dict.collider == self:
			_on_mouse_entered() 
			break

func check_status():
	pass
