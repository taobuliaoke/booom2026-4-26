extends Control

#导出路径
@onready var dialog_label = $MyCustomLabel
@onready var item_rect = $ItemBox

func _ready():
	# 重点：订阅 GameEvents 的“电报”，只要有人点屏幕，我就去检查
	GameEvents.global_clicked.connect(_on_global_clicked)

# 这个 id 是从 NPC 脚本传过来的
func show_content(id: String):
	#从GameDate里读Character_date
	var data= GameData.character_data.get(id,{})
	
	if data.is_empty():
		dialog_label.text = '……'
		item_rect.hide()
		return
	#填入自定义文本内容
	dialog_label.text = data.get('dialog','')
	
	#填入图片并显示
	var img_path = data.get('item_path','')
	if img_path != '':
		item_rect.texture = load(img_path)
		item_rect.show()
	else:
		item_rect.hide()
		 
func _on_global_clicked(event: InputEventMouseButton):
	# 如果我本来就没出来，那就不用理会
	if not visible:
		return
	
	# 【核心逻辑】
	# get_global_rect() 获取这个 UI 面板在屏幕上的矩形区域
	# has_point(点击位置) 判断你点的地方在不在这个矩形里
	if not get_global_rect().has_point(event.global_position):
		print("点到 UI 外面了，收起面板")
		hide() # 收起面板
