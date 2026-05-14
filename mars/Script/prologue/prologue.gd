extends Control

# 直接在编辑器里把这些节点拖到数组里
@export var to_minigame_slide:int
@export var special_slides :Array[Node2D]
@export var slide_nodes: Array[Node2D] = []
var final_slide : int

signal item_clicked
func _ready():
	final_slide = slide_nodes.size()-1
	$CanvasLayer/AnimationPlayer.play("fade_in")
	item_clicked.connect(_on_item_clicked)
	for i in range(slide_nodes.size()):
		slide_nodes[i].visible = (i ==GlobalData.current_page)
	
# 通用的跳转函数
func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 如果当前不是特殊交互页，则允许全屏点击翻页
			if slide_nodes[GlobalData.current_page] not in special_slides:
				go_to_next_step()
			else:
				print("这一页必须点中特定物品才能继续")
				
func go_to_next_step():
	print(GlobalData.current_page)
	if GlobalData.current_page == to_minigame_slide:
		SceneChanger.change_scene("res://3D_Content/3Dgame.tscn")
		GlobalData.current_page=to_minigame_slide+1
		return
	if GlobalData.current_page == final_slide:
		print("正在进入主场景...")
		SceneChanger.change_scene("res://Scenes/Level/MainScene.tscn") # 替换为你主场景的路径
		return
	if GlobalData.current_page >= slide_nodes.size() - 1:
		print("已经没有更多幻灯片了！")
		return

	set_process_unhandled_input(false)
	$CanvasLayer/AnimationPlayer.play("fade_out")
	await $CanvasLayer/AnimationPlayer.animation_finished
	
	_change_slide_content()
	
	$CanvasLayer/AnimationPlayer.play("fade_in")
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

	go_to_next_step()
