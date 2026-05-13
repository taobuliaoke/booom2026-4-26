extends Control

# 直接在编辑器里把这些节点拖到数组里
@export var slide_nodes: Array[Node2D] = []
var special_slides = [2,3]
var current_step = 0
signal item_clicked
func _ready():
	# 初始化：隐藏所有，只显示第一张
	$CanvasLayer/AnimationPlayer.play("fade_in")
	item_clicked.connect(_on_item_clicked)
	for i in range(slide_nodes.size()):
		slide_nodes[i].visible = (i == 0)
	
# 通用的跳转函数
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 如果当前不是特殊交互页，则允许全屏点击翻页
			if current_step not in special_slides:
				go_to_next_step()
			else:
				print("这一页必须点中特定物品才能继续")
				
func go_to_next_step():
	# 1. 播放“亮转黑”
	set_process_unhandled_input(false)
	$CanvasLayer/AnimationPlayer.play("fade_out")
	await$CanvasLayer/AnimationPlayer .animation_finished
	
	# 2. 隐藏当前页，显示下一页
	_change_slide_content()
	
	# 3. 播放“黑转亮”
	$CanvasLayer/AnimationPlayer.play("fade_in")
	set_process_unhandled_input(true)

func _change_slide_content():
	if current_step < slide_nodes.size() - 1:
		slide_nodes[current_step].hide()
		current_step += 1
		slide_nodes[current_step].show()
	

func _on_item_clicked():

	go_to_next_step()
