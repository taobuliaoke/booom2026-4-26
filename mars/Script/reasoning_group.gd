extends Control


@export var level_win_se: AudioStream

var pages_cleared = 0
const TOTAL_PAGES = 3

func check_global_victory():
	pages_cleared += 1
	print('当前完成',pages_cleared)
	if pages_cleared >=TOTAL_PAGES:
		MusicManager.fade_out_and_stop(0.5)
		
		start_transition_to_end()
		
func start_transition_to_end():
	print('finished')
	MusicManager.play_se(level_win_se,5.0)
	get_tree().change_scene_to_file('res://Scenes/booom_end.tscn')
