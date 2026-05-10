extends Area2D
var is_hovering = false
var word_card_scene = preload("res://Scenes/word_card.tscn")



# 在编辑器右侧直接填词条
@export var word_name: String = "……"

func _ready():
	#鼠标监听
	input_pickable = true

	#每次这个线索出现在屏幕上时，检查状态
	visibility_changed.connect(_on_visibility_changed)
	#其他视角同名物品被捡走的时候，也要更新状态
	add_to_group('clue_items')
	check_status()
	

func _on_visibility_changed():
	if is_visible_in_tree():
		check_status()
		

func check_status():
	if word_name == "" or word_name == "……": 
		return

	#  只有当 registry 里确实有这个特定的词时才禁用
	if GameEvents.clues_registry.get(word_name, false):
		if has_node("../RedMarker"):
			get_node("../RedMarker").hide()

func _on_clicked():
	if GameEvents.collect_clue(word_name):
		#成功收集，通知本关卡所有视角里的同名线索更新状态
		get_tree().call_group('clue_items','check_status')

		print('点击了信件内部的交互物:',word_name)
		
# 在 Interactable_4.gd 中添加

func _on_mouse_entered():
	is_hovering = true 
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	#弹出对话框
	print(GameData)
	
	
func _on_mouse_exited():
	is_hovering = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _input_event(_viewport, event, _shape_idx):
	# 只要是鼠标左键按下
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("点到我了")
		collect_this_word()

func collect_this_word():
	if word_name == "": return
	
	# 只有在全局账本里还没拿过这个词时，才执行
	if GameEvents.collect_clue(word_name):
		#  只调用这一行！它会负责检查重复并发出“加词”信号
		GameEvents.add_word(word_name)
		
		# 通知本关所有视角的同名物品变灰
		get_tree().call_group("clue_items", "check_status")
		
		#  禁用自己的碰撞，防止连点
		$CollisionShape2D.set_deferred("disabled", true)
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		print("成功触发全局加词逻辑：", word_name)
