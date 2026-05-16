extends Control

# --- 编辑器变量 ---
@export var typing_speed: float = 0.05
@export_file("*.tscn") var next_scene_path: String = "res://Scenes/title_screen.tscn"

# --- 节点引用 ---
@onready var dialogue_label = $CanvasLayer/Label

# --- 核心数据与状态机 ---
# 既然不需要切换 slide，直接把对白文本塞进一个纯数组里即可
var dialogues: Array[String] = [
	"沈德渊用银票贿赂周之瀚，希望其将女儿沈慧心的名字加进留洋名单。",
	"周之瀚把自己的女儿，周静姝的名字划掉，换成了沈慧心。",
	"神仙？在周之瀚身后。",
	"偷偷看。",
	"恭喜你通关了《荧惑仙》2026booom版本的试玩关卡",
	"期待和你再次见面",
	"……",
	"我要切换到标题画面了",
]

var current_index: int = 0
var is_typing: bool = false
var current_tween: Tween

func _ready():
	# 确保标签初始是干净的
	dialogue_label.text = ""
	# 开始播放第一句
	_show_current_dialogue()

func _unhandled_input(event):
	# 监听鼠标左键点击
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		# 状态 1：如果正在打字，点击瞬间显示全
		if is_typing:
			_finish_typing_instantly()
			return
			
		# 状态 2：字已经显示完了，检查是否还有下一句
		if current_index < dialogues.size() - 1:
			current_index += 1
			_show_current_dialogue()
		else:
			# 状态 3：所有对白都播完了，执行结束逻辑（如跳转场景）
			_on_dialogue_finished()

# 核心：渲染当前行的对白
func _show_current_dialogue():
	if current_index < dialogues.size():
		_start_typing(dialogues[current_index])

# 打字机效果核心实现
func _start_typing(content: String):
	is_typing = true
	dialogue_label.text = content
	dialogue_label.visible_ratio = 0.0
	
	if current_tween: 
		current_tween.kill()
	current_tween = create_tween()
	
	var duration = content.length() * typing_speed
	current_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	
	# 动画正常播完，解除打字状态
	current_tween.finished.connect(func(): is_typing = false)

# 瞬间显示完整文本
func _finish_typing_instantly():
	if current_tween: 
		current_tween.kill()
	dialogue_label.visible_ratio = 1.0
	is_typing = false

# 终点逻辑：所有对话播放完毕后的处理
func _on_dialogue_finished():
	print("所有对话已播放完毕！准备跳转下一场景。")
	set_process_unhandled_input(false) # 禁用输入防连点
	if next_scene_path != "":
		# 这里可以用你原本的 SceneChanger，或者 Godot 自带的切换
		get_tree().change_scene_to_file(next_scene_path)
