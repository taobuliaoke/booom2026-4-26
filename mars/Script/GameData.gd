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
	var matches = regex.search_all(raw_text)
	
	# 统一使用这个数组
	var words_data = [] 
	
	# 生成视觉用的 BBCode 文本
	var formatted_text = regex.sub(raw_text, "[color=red][u]$1[/u][/color]", true)
	# 生成计算坐标用的干净文本
	var clean_text = regex.sub(raw_text, "$1", true)
	
	var offset = 0
	for m in matches:
		var word = m.get_string(1)
		# 每一个词条前面的花括号会对索引造成干扰，这里减去累积的括号长度
		var start_index = m.get_start() - offset
		
		words_data.append({
			"word": word,
			"index": start_index,
			"length": word.length()
		})
		offset += 2 # 每处理一个词，就意味着干净文本里少了两个字符（{ 和 }）
		
	return {
		"text": clean_text,
		"formatted_text": formatted_text,
		"data": words_data # 确保这里返回的是装满数据的数组！
	}
