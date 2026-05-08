extends Control

@onready var library = $LetterLibrary # 确保场景里有这个节点

func _ready() -> void:
	visible = false
	# 初始化：关掉所有信的显示
	if library:
		for child in library.get_children():
			child.visible = false
	
	GameEvents.request_item_detail.connect(show_letter_by_node_name)
	GameEvents.global_clicked.connect(_on_global_clicked)
	GameEvents.request_letter_open.connect(show_letter_by_node_name)

func show_letter_by_node_name(node_name:String) -> void:
	if node_name == '' or  not library:
		return
	# 先清理：隐藏所有信件防止重复显示
	for child in library.get_children():
		child.visible = false
		
	# 找到对应名字的信来显示
	var target_node = library.get_node_or_null(node_name)
	if target_node:
		target_node.visible = true
		self.visible = true
		GameEvents.is_sub_ui_open = true #锁定地图点击
	else:
		push_error("找不到信件节点: " + node_name)

func _on_global_clicked(event: InputEventMouseButton) -> void:
	if not visible: 
		return
	
	# 等待一帧，防止点击触发物时直接就把信给关了
	await get_tree().process_frame
	
	# 寻找当前正在显示的信纸
	var current_paper: Control = null
	for child in library.get_children():
		if child.visible:
			current_paper = child
			break
	
	# 判定逻辑：如果点击的位置在信纸图片的区域之外，就关闭
	if current_paper:
		#获取信纸在大屏幕上的实际区域
		var rect = current_paper.get_global_rect() 
		if not rect.has_point(event.global_position):
			close_letter()
		else:
			print('交给信件内部的interactable')

func close_letter():
	visible = false
	GameEvents.is_sub_ui_open = false
