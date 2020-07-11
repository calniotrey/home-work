extends PanelContainer

signal selected_signal(value)

signal selected_task_signal(value)

var TIME_MANAGEMENT = 1.0

var skill = 0.5
var relationships = []
var time_since_last_interaction = 0.0
var modifiers = []
var current_task = null
var current_prefered_task = null
var list_index = 0 # the index of the refacto/debug/doc he's currently working on
var time_until_task_change = 0

# Modifiers
var isDisturbed = false
var isSatisfied = false
var isAngry = false

# Traits
var traits = []

func _ready():
	$SpeakTimer.wait_time = randf() * 400
	$SpeakTimer.start()
	set_random_traits()
	set_random_task_preference()
	set_random_task()

func set_random_traits(): # TODO add difficulty impact
	if randf() < 0.2:
		traits.append("autonomous")
	elif randf() < 0.2 / 0.8: # 20% chance
		traits.append("slacker")
	if randf() < 0.1:
		traits.append("annoying")
	if randf() < 0.1:
		traits.append("ambitious")
	if randf() < 0.1:
		traits.append("managophobe")
	if randf() < 0.1:
		traits.append("gamer")

func set_random_task_preference(): # TODO add difficulty impact
	var r = randf()
	if r < 0.2:
		current_prefered_task = "feature"
	elif r < 0.4:
		current_prefered_task = "documentation"
	elif r < 0.6:
		current_prefered_task = "debug"
	elif r < 0.8:
		current_prefered_task = "refactoring"
	elif r < 0.2:
		current_prefered_task = "architecture"

func set_random_task(): # TODO add difficulty impact
	var r = randf()
	var feature_weight = 0.5
	var documentation_weight = 0.1
	var debug_weight = 0.3
	var refactoring_weight = 0.1
	if current_task == "feature":
		feature_weight *= 3.0
	elif current_task == "documentation":
		documentation_weight *= 3.0
	elif current_task == "debug":
		debug_weight *= 3.0
	elif current_task == "refactoring":
		refactoring_weight *= 3.0
	if current_prefered_task == "feature":
		feature_weight *= 2.0
	elif current_prefered_task == "documentation":
		documentation_weight *= 2.0
	elif current_prefered_task == "debug":
		debug_weight *= 2.0
	elif current_prefered_task == "refactoring":
		refactoring_weight *= 2.0
	var total_weight = feature_weight + documentation_weight + debug_weight + refactoring_weight
	r *= total_weight
	if r < feature_weight:
		set_task("feature")
	elif r < feature_weight + documentation_weight:
		set_task("documentation")
	elif r < feature_weight + documentation_weight + debug_weight:
		set_task("debug")
	elif r < feature_weight + documentation_weight + debug_weight + refactoring_weight:
		set_task("refactoring")

func set_task(task):
	if task == "feature":
		current_task = "feature"
	elif task == "documentation":
		current_task = "documentation"
	elif task == "debug":
		current_task = "debug"
	elif task == "refactoring":
		current_task = "refactoring"
	#print("New task : ", current_task)
	time_until_task_change = randf()*3 + 2
	emit_signal("selected_task_signal", self)
	
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


func _on_Coworker_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		emit_signal("selected_signal", self)

func get_avatar():
	return $Avatar

func get_task_factor():
	if current_task == "refactoring":
		return 0.1
	elif current_task == "documentation":
		return 0.01
	elif current_task == "debug":
		return 0.8
	elif current_task == "feature":
		return 1.0
	elif current_task == "architecture":
		return 0.1
	elif current_task == "meeting":
		return 0.0001
	elif current_task == "gaming":
		return 0.0001
	return 1.0

func get_managed_factor():
	var factor = 1.0
	if traits.has("autonomous"):
		factor *= .5 * (2.0 - exp(-time_since_last_interaction/TIME_MANAGEMENT))
	if traits.has("slacker"):
		factor *= exp(-3.0 * time_since_last_interaction/TIME_MANAGEMENT)
	if traits.has("managophobe"):
		factor *= .5 * (2.0 - exp(-time_since_last_interaction/TIME_MANAGEMENT))
	return factor
	
func get_raw_production():
	return (randf() * 0.2 + 0.8) * skill * get_managed_factor() * get_task_factor()
