extends Control # 建议根节点用 Control 方便做全屏判定

@onready var content_label = $LetterContent # 对应你显示信件内容的标签
@onready var paper_rect =  $letter            # 对应你信件的背景底图

func _ready() -> void:
	visible = false
	GameEvents.request_item_detail.connect(show_content)
	GameEvents.global_clicked.connect(_on_global_clicked)

# content 是从对话框 UI 传过来的 info.get("content", "")[cite: 2]
func show_content(content: String) -> void:
	GameEvents.is_sub_ui_open = true 
	content_label.text = content
	visible = true

func _on_global_clicked(event: InputEventMouseButton) -> void:
	if not visible:
		return
		
	# 3. 同样的“等一帧”避开开启时的点击
	await get_tree().process_frame
	
	# 4. 判定点击是否在信件纸张外面
	var rect = paper_rect.get_global_rect()
	if not rect.has_point(event.global_position):
		close_letter()

func close_letter():
	hide()
	GameEvents.is_sub_ui_open = false
