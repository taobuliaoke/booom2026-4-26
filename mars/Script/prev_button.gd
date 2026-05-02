extends TextureButton
func _on_pressed():
	GameEvents.emit_signal("request_prev_view")
