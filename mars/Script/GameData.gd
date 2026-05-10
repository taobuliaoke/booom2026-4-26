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
	regex.compile("\\{(.*?)\\}")
	
	var formatted_text = raw_text
	var words_data = []
	
	# --- 改进点 1: 先生成干净文本，同时记录准确索引 ---
	var clean_text = ""
	var last_pos = 0
	var matches = regex.search_all(raw_text)
	
	for m in matches:
		# 添加大括号之前的普通文本
		clean_text += raw_text.substr(last_pos, m.get_start() - last_pos)
		
		var word = m.get_string(1)
		# 此时 clean_text.length() 就是该词条在纯文本中的准确起始位置
		words_data.append({
			"word": word,
			"index": clean_text.length(), 
			"length": word.length()
		})
		
		# 将词条内容加入干净文本
		clean_text += word
		last_pos = m.get_end()
	
	# 添加剩余文本
	clean_text += raw_text.substr(last_pos)
	
	# --- 改进点 2: 倒序生成用于 RichTextLabel 显示的格式化文本 ---
	for i in range(matches.size() - 1, -1, -1):
		var m = matches[i]
		var word = m.get_string(1)
		var is_picked = GameEvents.clues_registry.get(word, false)
		var color_tag = "#444444" if is_picked else "red" 
		
		var replacement = "[color=%s][u]%s[/u][/color]" % [color_tag, word]
		formatted_text = formatted_text.erase(m.get_start(), m.get_end() - m.get_start())
		formatted_text = formatted_text.insert(m.get_start(), replacement)

	return {
		"text": clean_text,
		"formatted_text": formatted_text,
		"data": words_data
	}
