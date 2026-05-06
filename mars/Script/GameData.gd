# GameData.gd
extends Node
# 存储当前加载好的关卡资源
var current_level_data: LevelData

# 快捷访问属性
var item_descriptions: Dictionary:
	get: return current_level_data.item_descriptions if current_level_data else {}

var character_data: Dictionary:
	get: return current_level_data.character_data if current_level_data else {}

# --- 你提供的 JSON 加载函数 ---
func load_data_from_json(path: String):
	if not FileAccess.file_exists(path):
		print("找不到文件: ", path)
		return null
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	var dict = JSON.parse_string(json_text)
	
	if dict == null:
		print("JSON 解析失败，请检查格式是否正确（不能有注释！）")
		return null
	
	var new_data = LevelData.new()
	new_data.item_descriptions = dict.get("item_descriptions", {})
	new_data.character_data = dict.get("character_data", {})
	
	# 将加载好的数据存入全局变量
	current_level_data = new_data
	return new_data
func parse_pickable_text(raw_text: String) -> Dictionary:
	var regex = RegEx.new()
	regex.compile("\\{(.*?)\\}") # 匹配 {} 里的内容
	var matches = regex.search_all(raw_text)
	
	var clean_text = raw_text.replace("{", "").replace("}", "")
	var pickable_data = [] # 存储词条信息
	
	var offset = 0
	for m in matches:
		var word = m.get_string(1)
		var start_index = m.get_start() - offset
		pickable_data.append({
			"word": word,
			"index": start_index,
			"length": word.length()
		})
		offset += 2 # 每匹配一个词，去掉了两个括号
		
	return {"text": clean_text, "data": pickable_data}
