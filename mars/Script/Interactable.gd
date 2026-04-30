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
	
	var new_card = word_card_scene.instantiate()
	new_card.get_node('MarginContainer/Label').text = word_name
	$"../../../UiLayer/Inventory".add_child(new_card)
	# 1. 调用你之前的全局加词逻辑
	GameEvents.add_word(word_name)
	
	# 2. 视觉反馈：让物品图片变淡
	# owner 指的是这个组件被挂载到的那个“大节点”（比如你的 Sprite2D）
	#if owner is CanvasItem:
		#owner.modulate.a = 0.5
		
	# 3. 禁用点击，防止点第二次
	# set_deferred 是为了安全地在物理帧关闭碰撞
	$CollisionShape2D.set_deferred("disabled", true)
	print("成功收集词条：", word_name)
