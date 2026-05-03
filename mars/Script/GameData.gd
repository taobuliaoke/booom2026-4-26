# GameData.gd
extends Node
var current_level_data : LevelData

# 线索表：用于普通的 Interactable 物品
var item_descriptions:
	get:
		return current_level_data.item_descriptions if current_level_data else {}


# 角色表：用于 NPC 的详细交互
var character_data:
	get:
		return current_level_data.character_data if current_level_data else {}

func load_level_data(path: String):
	current_level_data = load(path)
