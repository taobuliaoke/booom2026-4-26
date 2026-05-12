extends Node2D
@export var data_resource_path: String
@export var blink_duration:float = 0.2 #(眨眼动画时间)

@onready var old_icon = $"../../UiLayer/IconContainer/TextureRect/OldIcon"
@onready var current_icon =$"../../UiLayer/IconContainer/TextureRect/CurrentIcon"
@export var view_icons: Array[Texture2D]   # ... 按视角顺序排列
@export var slide_duration: float = 0.3 # 滑动持续时间


@onready var viewpoints_container = $Viewpoints
#引用眼睑节点
@onready var upper_lid =$"../../UiLayer/BlinkCanvas/UpperLid"
@onready var lower_lid =$"../../UiLayer/BlinkCanvas/LowerLid"

# 记录当前看的是第几个视角（从 0 开始）
var current_view_index: int = 0
var is_blinking:bool = false

func _ready():
	#初始化时先让眼睑完全张开
	upper_lid.custom_minimum_size.y = 0
	lower_lid.custom_minimum_size.y = 0
	
	if data_resource_path != "":
	# 游戏开始时加载第一关的 JSON[cite: 12]
		GameData.load_data_from_json("res://Script/Resourse/level_1_data.json")
	# 游戏开始时，先刷新一次，确保只显示第一个视角
	update_views()
func _on_prev_button_pressed() -> void:
	if is_blinking or not viewpoints_container or viewpoints_container.get_child_count() == 0:
		return
		
	var total_views = viewpoints_container.get_child_count()
	current_view_index = (current_view_index - 1 + total_views) % total_views
	
	if $"../../ReasoningPage".visible:
		update_views()
		switch_icon(-1)
	else:
		switch_icon(-1) # 正常向左滑动
		play_blink_transition()


func _on_next_button_pressed() -> void:
		#如果在眨眼，拦截，不执行任何逻辑
	if is_blinking or not viewpoints_container or viewpoints_container.get_child_count() == 0:
		return
	var total_views = viewpoints_container.get_child_count()
	current_view_index = (current_view_index + 1) % total_views
	
	if $"../../ReasoningPage".visible:
		update_views() # 直接更新视角
		switch_icon(1)
	else:
		switch_icon(1)
		play_blink_transition() # 眨眼切换

#眨眼动效方法
func play_blink_transition():
	
	is_blinking = true #锁上
	var screen_height = get_viewport_rect().size.y
	var half_height = screen_height / 2.0
	
	# 创建一个默认非并行的 Tween 序列
	var tween = create_tween()
	
	# --- 阶段 1：闭眼 (上下同时) ---
	# 使用 set_parallel() 让这两个动画同步进行
	tween.set_parallel(true)
	tween.tween_property(upper_lid, "custom_minimum_size:y", half_height, blink_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(lower_lid, "custom_minimum_size:y", half_height, blink_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	# --- 阶段 2：切换视角 ---
	# 使用 chain() 强制要求接下来的操作必须在前面的动画完成后执行
	# 并且通过 set_parallel(false) 回到序列执行模式
	tween.chain().set_parallel(false)
	tween.tween_callback(update_views)
	
	# (可选) 在全黑状态下稍微停留一小会儿，增加打击感
	tween.tween_interval(0.05) 
	
	# --- 阶段 3：睁眼 (上下同时) ---
	tween.set_parallel(true)
	tween.tween_property(upper_lid, "custom_minimum_size:y", 0.0, blink_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(lower_lid, "custom_minimum_size:y", 0.0, blink_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

# 阶段 4：彻底完成动画后解锁
	tween.chain().set_parallel(false)
	tween.tween_callback(func(): is_blinking = false) # 使用匿名函数解锁


# 核心：根据序号决定谁显示，谁隐藏
func update_views():
	if not viewpoints_container:
		return


	var views = viewpoints_container.get_children()
	for i in range(views.size()):
		views[i].visible = (i == current_view_index)

	
func switch_icon(direction: int):
	if view_icons.size() == 0: return

	# 1. 准备旧图层（当前显示的图变成底图）
	old_icon.texture = current_icon.texture
	old_icon.position = Vector2.ZERO
	
	# 2. 准备新图层（设置新贴图并瞬移到侧边）
	current_icon.texture = view_icons[current_view_index]
	var offset_x = current_icon.size.x * direction
	current_icon.position = Vector2(offset_x, 0)
	
	# 3. 立即执行滑入 Tween
	# 这样玩家点击的一瞬间，图标就开始动了，而背景还在等眨眼
	var icon_tween = create_tween()
	icon_tween.tween_property(current_icon, "position", Vector2.ZERO, 0.25)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)
