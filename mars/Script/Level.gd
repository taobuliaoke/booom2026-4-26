extends Node2D
@export var data_resource_path: String


# 记录当前看的是第几个视角（从 0 开始）
var current_view_index: int = 0
# 引用存放视角的容器
@onready var viewpoints_container = $Viewpoints

func _ready():
	if data_resource_path != "":
		GameData.load_level_data(data_resource_path)
	# 游戏开始时，先刷新一次，确保只显示第一个视角
	update_views()
	GameEvents.request_next_view.connect(_on_next_pressed)
	GameEvents.request_prev_view.connect(_on_prev_pressed)
	update_views()
	
# 点击“右翻”按钮连接到这个函数
func _on_next_pressed():
	#安全检查，没有子节点时不执行
	if not viewpoints_container or viewpoints_container.get_child_count() == 0:
		return
	# 获取总共有几个视角
	var total_views = viewpoints_container.get_child_count()
	# 序号 +1，如果超过最大值就回到 0 (循环翻页)
	current_view_index = (current_view_index + 1) % total_views
	update_views()

# 点击“左翻”按钮连接到这个函数
func _on_prev_pressed():
	if not viewpoints_container or viewpoints_container.get_child_count() == 0:
		return
	var total_views = viewpoints_container.get_child_count()
	# 序号 -1，如果小于 0 就跳到最后一个
	current_view_index = (current_view_index - 1 + total_views) % total_views
	update_views()

# 核心：根据序号决定谁显示，谁隐藏
func update_views():
	if not viewpoints_container:
		return
	
	var views = viewpoints_container.get_children()
	for i in range(views.size()):
		if i == current_view_index:
			views[i].show()     # 显示当前序号的视角
		else:
			views[i].hide()     # 隐藏其他的
