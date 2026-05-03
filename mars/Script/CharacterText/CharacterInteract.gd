extends Area2D

# 这里的 word_name 可以作为角色的 ID，用来提取对应的文本和道具
@export var character_id: String = "沈慧心"
# 引用你想要弹出的 UI 界面（文本框和道具展示框的组合体）
@onready var dialog_ui = $"../CharacterDialogUI"

func _ready():
	input_pickable = true # 必须开启，否则点不到
	mouse_entered.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)) # 变小手
	mouse_exited.connect(func(): Input.set_default_cursor_shape(Input.CURSOR_ARROW)) # 恢复

func _input_event(_viewport, event, _shape_idx):
	# 如果点的是左键
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_interact()
		#if dialog_ui:
			#dialog_ui.show_content(character_id) # 告诉 UI 该显摆谁了
			#dialog_ui.show() # 弹出面板

func _interact():
	# 从 GameData 获取该角色的配置
	var data = GameData.character_data.get(character_id, {})
	if data.is_empty(): return
	if GameEvents.is_in_dialogue:return
	print(GameEvents.is_in_dialogue)
	# 发出信号，通知 UI 层弹出对话框
	GameEvents.emit_signal("request_character_dialog", character_id)
	GameEvents.is_in_dialogue = true
	
