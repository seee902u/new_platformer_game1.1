extends Node2D

@onready var mobs: Node2D = $".."
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var spawn_count = 0
var mushroom_preload = preload("res://Mobs/mushroom.tscn")

func _ready() -> void:
	Signals.connect("day_time", Callable(self, "_on_time_changed"))
	
func _on_time_changed (state, day_count):
	spawn_count = 0
	var rng = randi_range(0, 3)
	if state == 1:
		for i in (day_count + rng):
			animation_player.play("spawn")
			await animation_player.animation_finished
			spawn_count += 1
			
	if spawn_count == day_count + rng:
		animation_player.play("Idle")
	

func mushroom_spawn ():
	var  mushroom = mushroom_preload.instantiate()
	mushroom.position = Vector2(self.position.x,570)
	mobs.add_child(mushroom)
