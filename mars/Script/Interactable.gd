extends Area2D

var word_card_scene = preload("res://Scenes/word_card.tscn")
# 在编辑器右侧直接填词条
@export var word_name: String = "周某"

func _ready():
	#鼠标监听
	input_pickable = true
	#连接信号
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	#监听视角切换或者场景进入
	#每次这个线索出现在屏幕上时，检查状态
	visibility_changed.connect(_on_visibility_changed)
	#其他视角同名物品被捡走的时候，也要更新状态
	add_to_group('clue_items')
	check_status()
	
	
func _on_visibility_changed():
	if is_visible_in_tree():
		check_status()
		

func check_status():
	#如果全局账本里显示这个词拿过了，就自毁交互性
	if GameEvents.clues_registry.get(word_name,false):
		$CollisionShape2D.disabled = true
		#owner.modulate.a = 0.5 #变灰
		

func _on_clicked():
	if GameEvents.collect_clue(word_name):
		#成功收集，通知本关卡所有视角里的同名线索更新状态
		get_tree().call_group('clue_items','check_status')
		
		
func _on_mouse_entered():
	#变icon
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	#弹出对话框
	print(GameData)
	var desc = GameData.item_descriptions.get(word_name,'聚精会神')
	#通知UI层显示文本
	GameEvents.emit_signal('show_tooltip',desc)
	
	
func _on_mouse_exited():
	#恢复普通箭头
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	# 告诉 UI 层：把对话框藏起来
	GameEvents.emit_signal("hide_tooltip")

func _input_event(_viewport, event, _shape_idx):
	# 只要是鼠标左键按下
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect_this_word()

func collect_this_word():
	if word_name == "": return
	
	# 只有在全局账本里还没拿过这个词时，才执行
	if GameEvents.collect_clue(word_name):
		# 1. 只调用这一行！它会负责检查重复并发出“加词”信号
		GameEvents.add_word(word_name)
		
		# 2. 通知本关所有视角的同名物品变灰
		get_tree().call_group("clue_items", "check_status")
		
		# 3. 禁用自己的碰撞，防止连点
		$CollisionShape2D.set_deferred("disabled", true)
		
		print("成功触发全局加词逻辑：", word_name)
