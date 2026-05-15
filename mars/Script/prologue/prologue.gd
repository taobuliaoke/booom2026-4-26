extends Control

# --- 编辑器变量 ---
@export_file("*.json") var data_file_path: String = "res://Script/Resourse/prologue_data.json" 
@export var to_minigame_slide: int 
@export var special_slides: Array[Node2D] 
@export var slide_nodes: Array[Node2D] = [] 
@export var typing_speed: float = 0.05 

# --- 节点引用 ---
@onready var dialogue_label = $CanvasLayer/DialogueLabel # 请确保你的场景中有此路径的 Label 

# --- 运行状态 ---
var dialogue_data: Array = []
var final_slide: int 
var is_typing: bool = false
var current_dialogue_index: int = 0
var current_tween: Tween

signal item_clicked 

func _ready():
	#防御性检查：确保inspector 已赋值
	if slide_nodes.is_empty():
		push_error('错误：slide_nodes 数组为空，请在inspector 中拖入了节点')
		return
	final_slide = slide_nodes.size() - 1 
	item_clicked.connect(_on_item_clicked) 
	
	# 加载 JSON 数据
	_load_dialogue_data()
	
	# 初始化显示状态
	$CanvasLayer/AnimationPlayer.play("fade_in") 
	for i in range(slide_nodes.size()):
		slide_nodes[i].visible = (i == GlobalData.current_page) 
	
	# 显示当前页的第一句对白
	_display_current_content()

func _load_dialogue_data():
	if not FileAccess.file_exists(data_file_path):
		print("错误：找不到对白文件 ", data_file_path)
		return
	
	var file = FileAccess.open(data_file_path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		dialogue_data = json.data["slides"]
	else:
		print("JSON 解析错误")

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: 
		var current_node = slide_nodes[GlobalData.current_page]
		
		# 1. 如果正在播字，点击瞬间显示全
		if is_typing:
			_finish_typing_instantly()
			return

		# 2. 检查这一页是否还有下一句对白
		var slide_info = dialogue_data[GlobalData.current_page]
		var dialogues = slide_info['dialogues']

		# 如果当前页有对话，且还没播完，则进入下一句
		if not dialogues.is_empty() and current_dialogue_index < dialogues.size() - 1:
			current_dialogue_index += 1
			_show_dialogue_step()
			return

		# 3. 如果对话播完了（或本来就没对话），检查是否是特殊交互页
		if current_node in special_slides or "Alien" in current_node.name: 
			print("对话已结束，请点击特定物品交互")
			return
		
		# 4. 执行翻页
		go_to_next_step()

func _display_current_content():
	current_dialogue_index = 0
	_show_dialogue_step()

func _show_dialogue_step():
	if GlobalData.current_page < dialogue_data.size():
		var slide_info = dialogue_data[GlobalData.current_page]
		var dialogues = slide_info['dialogues']
		
		#新增判断：如果当前页面没有对话内容，结束播字
		if dialogues.is_empty():
			is_typing = false
			dialogue_label.text = ''#清空上一页残留文字
			print('当前页面没有对话数据，点击直接翻页')
			return
		#如果有对话数据
		if current_dialogue_index < dialogues.size():
			_start_typing(dialogues[current_dialogue_index])

func _start_typing(content: String):
	is_typing = true
	dialogue_label.text = content
	dialogue_label.visible_ratio = 0.0
	
	if current_tween: current_tween.kill()
	current_tween = create_tween()
	
	var duration = content.length() * typing_speed
	current_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	current_tween.finished.connect(func(): is_typing = false)

func _finish_typing_instantly():
	if current_tween: current_tween.kill()
	dialogue_label.visible_ratio = 1.0
	is_typing = false

func go_to_next_step():
	if GlobalData.current_page == to_minigame_slide: 
		SceneChanger.change_scene("res://3D_Content/3Dgame.tscn") 
		GlobalData.current_page = to_minigame_slide + 1 
		return
		
	if GlobalData.current_page >= final_slide: 
		SceneChanger.change_scene("res://Scenes/Level/MainScene.tscn") 
		return

	set_process_unhandled_input(false) 
	$CanvasLayer/AnimationPlayer.play("fade_out") 
	await $CanvasLayer/AnimationPlayer.animation_finished 
	
	_change_slide_content() 
	
	$CanvasLayer/AnimationPlayer.play("fade_in") 
	_display_current_content() # 新页面开始显示文字
	set_process_unhandled_input(true) 

func _change_slide_content():
	var current_node = slide_nodes[GlobalData.current_page]
	if GlobalData.current_page < slide_nodes.size() - 1:
		slide_nodes[GlobalData.current_page].hide()
		GlobalData.current_page += 1
		slide_nodes[GlobalData.current_page].show()
		var particles = current_node.get_node_or_null("GPUParticles2D")
		if particles:
			particles.emitting = true # 开始发射
			particles.restart()       # 从头开始
	else:
		SceneChanger.change_scene("res://Scenes/MainScene.tscn")

func _on_item_clicked():
	# 只有字播完了，交互物品才有效
	if not is_typing:
		go_to_next_step()
