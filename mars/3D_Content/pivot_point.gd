extends Node3D
# --- 引用节点 ---
@onready var btn_mesh = $PuzzleObject/BtnMesh
@onready var limbs_container = $PuzzleObject/Limbs
# 修改这里，指向脱离了缩放层级的交互节点
@onready var btn_area = $InteractionLayer/Area3D
# --- 判定参数 ---
@export var target_rotation: Vector3 = Vector3(20.0, -156.0, 0.0)
@export var rot_threshold: float = 5.0
# --- 控制参数 ---
@export var rotate_speed: float = 0.5
@export var zoom_speed: float = 0.5
@export var zoom_min: float = 2.0
@export var zoom_max: float = 10.0
# --- 吸附参数 ---
@export var snap_threshold: float = 15.0
@export var snap_speed: float = 5.0
# --- 调试开关 ---
@export var debug_mode: bool = OS.is_debug_build()
# --- 内部状态 ---
var is_dragging: bool = false
var is_won: bool = false
var _debug_label: Label
var _fade_rect: ColorRect  # ← 新增
var limbs_deployed: bool = false
var btn_original_pos: Vector3


func _ready():
	btn_original_pos = btn_mesh.position
	# 连接点击信号
	btn_area.input_event.connect(_on_button_input)
	# 如果有其他逻辑请保留队友的 _ready 内容

	if debug_mode:
		_setup_debug_label()
		
func _on_button_input(_camera, event, _pos, _normal, _shape_idx):
	# 只有左键按下且还没长出肢体时触发
	print("点到我了！")
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		if not limbs_deployed:
			play_interaction_sequence()

func play_interaction_sequence():
	limbs_deployed = true
	
	# 1. 按钮按下反馈（向内移动再弹回）
	var btn_tween = create_tween()
	# 假设往内是局部 Z 轴负方向移动 0.1
	var pressed_pos = btn_original_pos + btn_mesh.transform.basis.z * -0.1
	
	btn_tween.tween_property(btn_mesh, "position", pressed_pos, 0.1)
	btn_tween.tween_property(btn_mesh, "position", btn_original_pos, 0.2).set_delay(0.1)
	
	# 2. 肢体生长序列
	btn_tween.finished.connect(_start_limbs_growth)

func _start_limbs_growth():
	# 在循环中添加	
	var limbs = limbs_container.get_children()
	var growth_tween = create_tween().set_parallel(true)
	for i in range(limbs.size()):
		var limb = limbs[i]
	# 如果你的肢体是 MeshInstance3D
		if limb is MeshInstance3D:
			limbs_container.show()

	
	
	for i in range(limbs.size()):
		var limb = limbs[i]
		var delay = i * 0.15 # 增加一点间隔感
		
		# 1. 记录它在编辑器里摆好的最终位置
		var target_pos = limb.position
		
		# 2. 计算“缩回”状态的起始位置
		# 我们让它沿着自己的局部 Z 轴负方向缩回 1.0 个单位
		# transform.basis.z 是物体当前面向的方向
		var start_pos = target_pos - limb.transform.basis.z * 0.2 
		
		# 3. 设置初始状态：缩回、透明、缩小
		limb.position = start_pos
		limb.scale = Vector3(0.1, 0.1, 0.1) # 不要设为0，防止数学计算报错
		
		# 4. 动画：沿着轴线“刺”出
		growth_tween.tween_property(limb, "position", target_pos, 0.7)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
			
		# 5. 动画：配合缩放，产生生长的力量感
		growth_tween.tween_property(limb, "scale", Vector3.ONE, 0.5)\
			.set_delay(delay)\
			.set_trans(Tween.TRANS_QUAD)
			
func _unhandled_input(event):
	if is_won:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	if event is InputEventMouseMotion and is_dragging:
		rotation_degrees.y += event.relative.x * rotate_speed
		rotation_degrees.x += event.relative.y * rotate_speed
		rotation_degrees.x = clamp(rotation_degrees.x, -89.0, 89.0)
	if debug_mode and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				target_rotation = rotation_degrees
				print("✓ 目标角度已记录：", rotation_degrees)
			KEY_F2:
				rotation_degrees = target_rotation
				print("✓ 已跳转到目标角度")
			KEY_F3:
				rotation_degrees = Vector3.ZERO
				print("✓ 已重置")


func _process(delta):
	if debug_mode and _debug_label:
		_update_debug_label()
	if not is_won and not is_dragging:
		_try_snap(delta)


func _try_snap(delta: float):
	var cur = rotation_degrees
	var dx = abs(fposmod(cur.x - target_rotation.x + 180, 360) - 180)
	var dy = abs(fposmod(cur.y - target_rotation.y + 180, 360) - 180)
	if dx < snap_threshold and dy < snap_threshold:
		var target_x = cur.x + (fposmod(target_rotation.x - cur.x + 180, 360) - 180)
		var target_y = cur.y + (fposmod(target_rotation.y - cur.y + 180, 360) - 180)
		rotation_degrees.x = lerp(cur.x, target_x, snap_speed * delta)
		rotation_degrees.y = lerp(cur.y, target_y, snap_speed * delta)
		_check_win()


func _check_win():
	var cur = rotation_degrees
	var dx = abs(fposmod(cur.x - target_rotation.x + 180, 360) - 180)
	var dy = abs(fposmod(cur.y - target_rotation.y + 180, 360) - 180)
	if dx < rot_threshold and dy < rot_threshold and limbs_deployed:
		is_won = true
		print("✓ 通关！角度：", cur.snapped(Vector3.ONE * 0.1))
		_on_win()


func _on_win():
	is_won = true
	SceneChanger.change_scene("res://Scenes/Level/prologue.tscn", 1.2) # ← 改成下一关的路径


func _start_fade_out(next_scene_path: String):
	var canvas := CanvasLayer.new()
	canvas.layer = 200
	get_tree().root.add_child(canvas)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(_fade_rect)

	var tween := get_tree().create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, 1.2) \
		 .set_ease(Tween.EASE_IN) \
		 .set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		get_tree().change_scene_to_file(next_scene_path)
	)


func _setup_debug_label():
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	add_child(canvas)
	_debug_label = Label.new()
	_debug_label.position = Vector2(16, 16)
	_debug_label.add_theme_font_size_override("font_size", 14)
	_debug_label.modulate = Color(1, 1, 0.2, 0.9)
	canvas.add_child(_debug_label)


func _update_debug_label():
	var cur = rotation_degrees.snapped(Vector3.ONE * 0.1)
	var tar = target_rotation
	var dx = abs(fposmod(cur.x - tar.x + 180, 360) - 180)
	var dy = abs(fposmod(cur.y - tar.y + 180, 360) - 180)
	var max_diff = max(dx, dy)
	var ratio = clamp(1.0 - max_diff / rot_threshold, 0.0, 1.0)
	var status: String
	if is_won:
		status = "✓ 通关!"
	elif ratio > 0.75:
		status = "△ 很接近了"
	elif ratio > 0.4:
		status = "… 继续调整"
	else:
		status = "✗ 未对齐"
	_debug_label.text = """[DEBUG]
当前角度   X:%-7.1f Y:%-7.1f
目标角度   X:%-7.1f Y:%-7.1f
各轴差距   X:%-7.1f Y:%-7.1f
匹配度     %.0f%%  %s
─────────────────────────
F1 记录目标角度
F2 跳转到目标角度
F3 重置旋转""" % [
		cur.x, cur.y,
		tar.x, tar.y,
		dx, dy,
		ratio * 100, status
	]
