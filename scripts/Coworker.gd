extends PanelContainer

signal selected(value)

signal selected_task_signal(value)

var TIME_MANAGEMENT = 1.0

var skill = 0.5
var relationships = []
var indicators = {
	"lines": 0.0,
	"commits": 0.0
}
var time_since_last_interaction = 0.0
var current_task = null
var current_prefered_task = null
var list_index = 0 # the index of the refacto/debug/doc he's currently working on
var time_until_task_change = 0
var time_spent_on_current_task = 0

# Modifiers
var is_disturbed = false
var is_satisfied = false
var is_angry = false

# Traits
var traits = []

const TASK_TO_LINES_AMOUNT = {
	"documentation": 2.0,
	"refactoring": 1.2,
	"feature": 1.0,
	"architecture": 0.25,
	"debug": 0.0,
	"meeting": 0.01,
	"gaming": 0.01
}
const TASK_TO_COMMITS_AMOUNT = {
	"documentation": 0.4,
	"refactoring": 1.2,
	"feature": 1.0,
	"architecture": 0.0,
	"debug": 2.0,
	"meeting": 0.01,
	"gaming": 0.01
}

func _ready():
	$SpeakTimer.wait_time = randf() * 400
	$SpeakTimer.start()

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

	#    v---- for ordering purposes
	var keys = ["feature", "documentation", "debug", "refactoring", "meeting", "gaming"]
	var weights = {
		"feature": 0.5,
		"documentation": 0.1,
		"debug": 0.3,
		"refactoring": 0.1,
		"meeting": 0.0,
		"gaming": 0.0
	}
	if current_task:
		weights[current_task] *= 3
	if current_prefered_task:
		weights[current_prefered_task] *= 2
	var total_weight = 0
	for w in weights.values():
		total_weight += w
	for w in weights.keys():
		weights[w] /= total_weight

	for key in keys:
		if r < weights[key]:
			set_task(key)
		else:
			r -= weights[key]

	time_spent_on_current_task = 0

func set_task(task):
	current_task = task
	time_until_task_change = randf()*3 + 2
	# print("Changed task : ", current_task)
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
		emit_signal("selected", self)

func get_avatar():
	return $Avatar

func get_task_factor():
	var task_to_production_value = {
		"refactoring": 0.1,
		"documentation": 0.01,
		"debug": 0.8,
		"feature": 1.0,
		"architecture": 0.1,
		"meeting": 0.0001,
		"gaming": 0.0001
	}
	return task_to_production_value.get(current_task, 1)

func get_managed_factor():
	var factor = 1.0
	if traits.has("autonomous"):
		factor *= .5 * (2.0 - exp(-time_since_last_interaction/TIME_MANAGEMENT))
	elif traits.has("slacker"):
		factor *= exp(-3.0 * time_since_last_interaction/TIME_MANAGEMENT)
	else:
		factor *= .5 * (1.0 + exp(-time_since_last_interaction/TIME_MANAGEMENT))
	if traits.has("managophobe"):
		factor *= .5 * (2.0 - exp(-time_since_last_interaction/TIME_MANAGEMENT))
	return factor

func get_modifiers_factor():
	var factor = 1.0
	if is_disturbed:
		factor *= .8
	if is_satisfied:
		factor *= 1.2
	elif is_angry:
		factor *= 0.5
	return factor

func get_raw_production():
	return (randf() * 0.2 + 0.8) * skill * get_managed_factor() * get_task_factor() * get_modifiers_factor()

func update_indicators(delta):
	indicators["lines"] += TASK_TO_LINES_AMOUNT.get(current_task, 1) * (0.5 + 0.5 * randf()) * delta
	indicators["commits"] += TASK_TO_COMMITS_AMOUNT.get(current_task, 1) * (0.5 + 0.5 * randf()) * delta
