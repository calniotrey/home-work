extends Node2D


var HOUR = 2


func _ready():
	
	for i in range(12):
		var tick
		if i % 3 == 0:
			tick = $BigTick.duplicate()
		else:
			tick = $SmallTick.duplicate()
		add_child(tick)
		tick.rotate(2*PI/12 * i)
		tick.visible = true


func _process(delta):
	var alpha_hour = 2*PI/12 * delta/HOUR
	$Hour.rotate(alpha_hour)
	
	var alpha_minute = alpha_hour * 60
	$Minute.rotate(alpha_minute)
