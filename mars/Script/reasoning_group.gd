extends Control
var pages_cleared = 0
const TOTAL_PAGES = 3

func check_global_victory():
	pages_cleared += 1
	print('当前完成',pages_cleared)
	if pages_cleared >=TOTAL_PAGES:
		start_transition_to_end()
		
func start_transition_to_end():
	print('finished')
	get_tree().change_scene_to_file('res://Scenes/booom_end.tscn')
