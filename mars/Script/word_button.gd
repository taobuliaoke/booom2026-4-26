extends Button
signal word_clicked(text)

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	word_clicked.emit(text)
	disabled = true
