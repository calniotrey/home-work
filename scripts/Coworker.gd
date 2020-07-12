extends PanelContainer

signal selected(value)

var TIME_MANAGEMENT = 10.0

const MIN_TIME_PER_TASK = 10.0
const MAX_TIME_PER_TASK = 30.0

var id = 0
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

onready var lines_graph = $Graphs/Lines
onready var commits_graph = $Graphs/Commits

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


const DIALOGS = {
	"documentation": [
		"Hmmm...",
		"They'll figure",
		"But this is obvious",
		"Just read the code"
	],
	"refactoring": [
		"Who wrote that?",
		"Why!?",
		"Interesting idea",
		"Original"
	],
	"feature": [
		"Improvisation is key",
		"Things are moving",
		"Quick and dirty",
		"Don't look"
	],
	"architecture": [
		"It will help",
		"No one needs this",
		"Maybe",
		"We need a factory"
	],
	"debug": [
		"Obviously",
		"Please work",
		"Ha ha!",
		"Finally..."
	],
	"meeting": [
		"Of course",
		"Yes, manager",
		"I respectfully disagree",
		"Why not?"
	],
	"gaming": [
		"I got you",
		"Headshot",
		"Bot is terrible",
		"The boss is mean"
	]
}


func _ready():
	plan_to_speak()


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
	elif r < 1:
		current_prefered_task = "architecture"


func set_random_task(): # TODO add difficulty impact
	var r = randf()

	#    v---- for ordering purposes
	var keys = ["architecture", "feature", "documentation", "debug", "refactoring", "meeting", "gaming"]
	var weights = {
		"architecture": 1.0,
		"feature": 5.0,
		"documentation": 1.0,
		"debug": 2.0,
		"refactoring": 1.0,
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
	time_spent_on_current_task = 0
	for key in keys:
		if r < weights[key]:
			set_task(key)
			return
		else:
			r -= weights[key]


func set_task(task):
	current_task = task
	time_until_task_change = randf() * (MAX_TIME_PER_TASK - MIN_TIME_PER_TASK) + MIN_TIME_PER_TASK
	#print("Coworker ", id, " changes task : ", current_task)


func plan_to_speak():
	$SpeakTimer.wait_time = randf() * 40
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
	plan_to_speak()


func _on_speaktimer_timeout():
	if current_task != null:
		var texts = DIALOGS[current_task]
		var k = randi() % len(texts)
		speak(texts[k])


func _on_Coworker_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		emit_signal("selected", self)

func get_avatar():
	return $Avatar

func get_task_factor():
	var task_to_production_value = {
		"refactoring": 0.1,
		"documentation": 0.01,
		"debug": 0.1,
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
	var random_factor = (0.5 + 0.5 * randf()) * delta
	var line_prod = TASK_TO_LINES_AMOUNT.get(current_task, 1) * random_factor
	indicators["lines"] += line_prod
	$Graphs/Lines.add_point(line_prod)
	
	random_factor = (0.5 + 0.5 * randf()) * delta
	var commit_prod = TASK_TO_COMMITS_AMOUNT.get(current_task, 1) * random_factor
	indicators["commits"] += commit_prod
	$Graphs/Commits.add_point(commit_prod)


func debug_display(index):
	var raw_prod = get_raw_production() # random is rerolled, but still good indicator
	print("Coworker ", index, " produces raw ", raw_prod, " and works on ", current_task)
	if traits.has("autonomous"):
		print("Coworker ", index, " is autonomous")
	elif traits.has("slacker"):
		print("Coworker ", index, " is a slacker")
	if traits.has("annoying"):
		print("Coworker ", index, " is annoying")
	if traits.has("ambitious"):
		print("Coworker ", index, " is ambitious")
	if traits.has("managophobe"):
		print("Coworker ", index, " is managophobe")
	if traits.has("gamer"):
		print("Coworker ", index, " is a gamer")
	if is_disturbed:
		print("Coworker ", index, " is disturbed")
	if is_satisfied:
		print("Coworker ", index, " is satisfied")
	elif is_angry:
		print("Coworker ", index, " is angry")
