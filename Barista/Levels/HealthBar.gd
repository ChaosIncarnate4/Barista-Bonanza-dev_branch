extends ColorRect

var health
var timer: Timer
signal gameOver
var texRex = []

# Called when the node enters the scene tree for the first time.
func _ready():
	health = 3
	timer = $Timer
	texRex.append($Heart);
	texRex.append($Heart1);
	texRex.append($Heart2);
	timer.start()
	
func _on_timer_timeout():
	health -= 1
	print(health)
	if health >= 0 and health < texRex.size():
		texRex[health].hide()
		
	if health <= 0:
		emit_signal("gameOver")
		
	timer.start()
	
