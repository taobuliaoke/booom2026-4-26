extends Control

@onready var item_preview =$Itempreview #展示框子拿来


func _ready():
	# 重点：订阅 GameEvents 的“电报”，只要有人点屏幕，我就去检查
	GameEvents.global_clicked.connect(_on_global_clicked)

# 这个 id 是从 NPC 脚本传过来的
func show_content(id: String):
	# 这里根据 id 去 GameData 里找对应的台词
	$RichTextLabel.text = GameData.item_descriptions.get(id, "我没有什么想给你的。")
	# 也可以在这里换道具图：$Icon.texture = load(...) 
	if id == '周某':
		item_preview.texture = load("res://art/Evidence/test.png") # 加载周某的钥匙[cite: 14]
		item_preview.show()
	else:
		item_preview.hide() # 没道具的角色就藏起来

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
