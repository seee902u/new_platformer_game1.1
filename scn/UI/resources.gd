extends CanvasLayer

@onready var gold_text: Label = $Control/PanelContainer/HBoxContainer/goldText

func _process(delta: float) -> void:
	gold_text.text = str(Global.gold)
