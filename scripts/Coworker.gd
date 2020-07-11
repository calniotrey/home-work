extends PanelContainer


func _ready():
	$SpeakTimer.wait_time = randf() * 400
	$SpeakTimer.start()


func speak(text):
	$BubbleCanvas.offset = rect_global_position + rect_size/2
	$BubbleCanvas/Bubble/Text.text = text
	$BubbleCanvas/Bubble/Timer.start()
	$BubbleCanvas/Bubble.visible = true


func stop_speaking():
	$BubbleCanvas/Bubble.visible = false


func _on_bubble_timer_timeout():
	stop_speaking()


func _on_speaktimer_timeout():
	speak("Please manage me " + self.name)
