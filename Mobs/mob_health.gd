extends Node2D

signal no_health ()
signal damage_received ()

@onready var health_bar = $HealthBar

@export var max_health = 100

var healht = 100:
	set (value):
		healht = value
		health_bar.value = healht
		if healht <= 0:
			health_bar.visible = false
		else:
			health_bar.visible = true

func _ready ():
	health_bar.max_value = max_health
	healht = max_health
	health_bar.visible = false


func _on_hurt_box_area_entered(_area: Area2D) -> void:
	await get_tree().create_timer(0.1).timeout
	healht -= Global.player_damage
	if healht <= 0:
		emit_signal("no_health")
	else:
		emit_signal("damage_received")
