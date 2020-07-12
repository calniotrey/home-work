extends Control

var coworkers_list = []
var selected_coworker = null
var coworker_managed = null

var diff_graph
var total_graph

var stop = false

var MAX_TIME_UNIT = 300.0
var TARGET_PRODUCTION = 1000.0
var IRL_TIME_PER_UNIT = 0.5 # TODO restore to 1 before getting good constants

var current_production = 0.0
var current_time = 0.0
var time_since_last_graph_append = 0.0
var production_since_last_graph_append = 0.0

var refactos_list = []
var docs_list = []
var time_spent_on_archi = 0
var time_since_last_emergency_meeting = 0
var total_time_elapsed = 0
var to_debug = 0
var debugging_done = 0


const ARCHI_THRESHOLD = 50
const TIME_REFACTO_CONSTANT = 10
const TIME_DOC_CONSTANT     = 10
const TIME_ARCHI_CONSTANT   = 10
const TIME_DEBUG_CONSTANT   = 10
const TIME_MEETING_CONSTANT = 10

const PRODUCTION_CONSTANT = 0.5
const RATIO_PRODUCTION_TO_DEBUG = 0.5

const P_DISTURBED_REMOVED   = 0.01
const P_SATISFIED_REMOVED   = 0.01
const P_ANGRY_REMOVED       = 0.01

const P_ANNOYING_EFFECT     = 0.001
const P_AMBITIOUS_EFFECT    = 0.001
const P_GAMING_INVITE       = 0.1
const GAMING_CONSTANT       = 10000.0

const REFACTORING_PROD      = 0.4
const DOC_PROD              = 0.2
const ARCHI_PROD            = 0.2
const DEBUG_PROD            = 0.2

const MEETING_DURATION      = 1.0
const ASSIGN_TASK_DURATION  = 5.0
const FLAME_DURATION        = 3.0
const EMERGENCY_MEETING_DURATION = 10.0

const REL_NEG_THRESHOLD     = 0.2
const REL_POS_THRESHOLD     = 0.8

const P_LIKES_FLAME         = 0.6
const P_HATES_FLAME         = 0.2

const MAX_REFACTO_FACTOR = 2.5
const MAX_DOC_FACTOR = 2.5
const MAX_ARCHI_FACTOR = 2

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	diff_graph = $VBoxContainer/Top/MainDisplay/Graphs/Diff
	diff_graph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	diff_graph.MAX_VALUE = TARGET_PRODUCTION / MAX_TIME_UNIT / 2.0
	diff_graph.average_required = TARGET_PRODUCTION / MAX_TIME_UNIT

	total_graph = $VBoxContainer/Top/MainDisplay/Graphs/Total
	total_graph.MAX_NUMBER_OF_POINTS = MAX_TIME_UNIT
	total_graph.MAX_VALUE = TARGET_PRODUCTION

	# Init all the coworkers
	var grids = [$VBoxContainer/Top/LeftCoworkerGrid, $VBoxContainer/Top/RightCoworkerGrid]
	for grid in grids:
		for coworker in grid.get_children():
			coworker.id = len(coworkers_list)
			coworker.connect("selected", self, "_coworker_selected")
			coworker.get_avatar().generate_face()
			coworkers_list.append(coworker)
			# TODO set skill
			coworker.set_random_traits()
			coworker.set_random_task_preference()
			coworker.set_random_task()
	for coworker_index in len(coworkers_list):
		for coworker_target_index in len(coworkers_list):
			coworkers_list[coworker_index].relationships.append(randf())
		coworkers_list[coworker_index].relationships[coworker_index] = 1 # likes himself

func _process(delta):
	add_time(delta)

	compute_production(delta)
	compute_coworkers_indicators(delta)
	change_tasks_if_necessary()
	coworkers_modifiers_check()
	coworkers_traits_effects()

	if not stop and time_since_last_graph_append >= IRL_TIME_PER_UNIT:
		debug_display()
#		for index in len(coworkers_list):
#			coworkers_list[index].debug_display(index)
		# print("append : ", current_production)
		current_time += 1
		time_since_last_graph_append -= IRL_TIME_PER_UNIT
		check_end_game()
		# print("current prod : ", current_production)
		total_graph.add_point(current_production)
		production_since_last_graph_append = min(diff_graph.MAX_VALUE, production_since_last_graph_append)
		diff_graph.add_point(production_since_last_graph_append)
		production_since_last_graph_append = 0

func add_time(delta):
	total_time_elapsed += delta
	time_since_last_graph_append += delta
	time_since_last_emergency_meeting += delta
	for coworker in coworkers_list:
		coworker.time_until_task_change -= delta
		coworker.time_spent_on_current_task += delta
		coworker.time_since_last_interaction +=  delta

func get_global_production_factors():
	var factors = {
		"refacto": 1,
		"doc": 1,
		"archi": 1,
		"debug": 1,
		"meeting": 1
	}
	for refacto in refactos_list:
		var time_since = total_time_elapsed - refacto[0]
		var time_spent = refacto[1]
		factors['refacto'] *= 1.0 + REFACTORING_PROD * exp(
			-1.0 * time_since / time_spent / TIME_REFACTO_CONSTANT
		)

	for doc in docs_list:
		var time_since = total_time_elapsed - doc[0]
		var time_spent = doc[1]
		factors['doc'] *= 1.0 + DOC_PROD * exp(
			-1.0 * time_since / time_spent / TIME_DOC_CONSTANT
		)
	factors['archi'] = 1.0 + ARCHI_PROD * min(
		1.0,
		exp(- (ARCHI_THRESHOLD - time_spent_on_archi) / TIME_ARCHI_CONSTANT)
	)

	factors['debug'] = min(1, exp(-1 * (to_debug - debugging_done)))


	factors['meeting'] = (0.5 + exp(-time_since_last_emergency_meeting / TIME_MEETING_CONSTANT))

	factors['refacto'] = min(factors['refacto'], MAX_REFACTO_FACTOR)
	factors['documentation'] = min(factors['refacto'], MAX_DOC_FACTOR)
	factors['archi'] = min(factors['archi'], MAX_ARCHI_FACTOR)

	return factors

func get_global_production_factor():
	var factors = get_global_production_factors()
	var total_factor = 1
	for factor in factors.values():
		total_factor *= factor
	return total_factor

func _coworker_selected(coworker):
	var cwk = $VBoxContainer/Top/MainDisplay/Graphs/CurrentWorker
	cwk.visible = true
	cwk.modulate.a = 1
	cwk.get_node("Avatar").copy(coworker.get_avatar())
	cwk.get_node("FadeTimer").start()

	var basic = $VBoxContainer/Bottom/IndicatorPanel/Basic
	
	if selected_coworker != null:
		basic.get_node("Lines/Graph").stop_copy_display_of(selected_coworker.lines_graph)
		basic.get_node("Commits/Graph").stop_copy_display_of(selected_coworker.commits_graph)
		
	basic.get_node("Lines/Graph").copy_display_of(coworker.lines_graph)
	basic.get_node("Commits/Graph").copy_display_of(coworker.commits_graph)
	
	selected_coworker = coworker


func compute_production(delta):
	var prod = 0.0
	for coworker in coworkers_list:
		if coworker.current_task == 'debug':
			debugging_done += coworker.time_spent_on_current_task * coworker.skill
			debugging_done = min(debugging_done, to_debug)

		var rp = coworker.get_raw_production()
		to_debug += PRODUCTION_CONSTANT * rp * delta * RATIO_PRODUCTION_TO_DEBUG
		var pf = get_global_production_factor()
		var p = PRODUCTION_CONSTANT * rp * pf * delta
		prod += p
		# print(rp, " : ", pf, " : ", p)
	production_since_last_graph_append += prod
	current_production += prod
	current_production = min(total_graph.MAX_VALUE, max(0, current_production))

func change_tasks_if_necessary():
	for coworker in coworkers_list:
		if coworker.time_until_task_change <= 0 and coworker.current_task != "meeting":
			var new_elem = [total_time_elapsed, coworker.time_spent_on_current_task]
			if coworker.current_task == "feature":
				pass
			elif coworker.current_task == "documentation":
				docs_list.append(new_elem)
			elif coworker.current_task == "debug":
				pass
			elif coworker.current_task == "refactoring":
				refactos_list.append(new_elem)
			elif coworker.current_task == "architecture":
				time_spent_on_archi += coworker.time_spent_on_current_task

			coworker.set_random_task()

func coworkers_modifiers_check():
	for index in len(coworkers_list):
		var coworker = coworkers_list[index]
		if coworker.is_disturbed and randf() < P_DISTURBED_REMOVED:
			print("Coworker ", index, " stops being disturbed")
			coworker.is_disturbed = false
		if coworker.is_satisfied and randf() < P_SATISFIED_REMOVED:
			print("Coworker ", index, " stops being satisfied")
			coworker.is_satisfied = false
		if coworker.is_angry and randf() < P_ANGRY_REMOVED:
			print("Coworker ", index, " stops being angry")
			coworker.is_angry = false

func coworkers_traits_effects():
	for index in len(coworkers_list):
		var coworker = coworkers_list[index]
		if coworker.traits.has("annoying") and randf() < P_ANNOYING_EFFECT:
			var random_index = randi() % (len(coworkers_list) - 1)
			if random_index >= index: # remove possibility to get same coworker
				random_index += 1
			coworkers_list[random_index].is_disturbed = true
			coworkers_list[random_index].relationships[index] *= 0.6 + 0.2*randf()
			print("Coworker ", index, " disturbs coworker ", random_index)
		if coworker.traits.has("ambitious") and randf() < P_AMBITIOUS_EFFECT:
			var random_index = randi() % (len(coworkers_list) - 1)
			if random_index >= index: # remove possibility to get same coworker
				random_index += 1
			var random_coworker = coworkers_list[random_index]
			random_coworker.time_since_last_interaction = 0
			random_coworker.relationships[index] *= 0.4 + 0.8*randf() # can increase, but unlikely
			random_coworker.relationships[index] = min(1.0, random_coworker.relationships[index])
			print("Coworker ", index, " 'manages' coworker ", random_index)
		if coworker.traits.has("gamer") and randf() > exp(-coworker.time_since_last_interaction / GAMING_CONSTANT ):
			coworker.set_task("gaming")
			print("Coworker ", index, " starts playing")
			# Invite other gamers
			for target_index in len(coworkers_list): # can invite himself, does nothing
				var coworker_target = coworkers_list[target_index]
				if coworker_target.traits.has("gamer") and randf() < P_GAMING_INVITE:
					print("Coworker ", index, " invites coworker ", target_index, " for a game")
					coworker_target.set_task("gaming")
					coworker_target.relationships[index] *= 0.8 + 0.6*randf()
					coworker_target.relationships[index] = min(1.0, coworker_target.relationships[index])

func compute_coworkers_indicators(delta):
	for coworker in coworkers_list:
		coworker.update_indicators(delta)

func check_end_game():
	if current_production >= TARGET_PRODUCTION:
		stop = true
		get_tree().change_scene("res://scenes/Victory.tscn")
	elif total_time_elapsed >= MAX_TIME_UNIT * IRL_TIME_PER_UNIT:
		stop = true
		get_tree().change_scene("res://scenes/Defeat.tscn")

func _on_start_fading():
	var cwk = $VBoxContainer/Top/MainDisplay/Graphs/CurrentWorker
	var tween = cwk.get_node("FadeTween")
	tween.interpolate_property(cwk, "modulate:a", 1, 0, 3,
							   Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_Meeting_button_down():
	if selected_coworker != null:
		selected_coworker.time_since_last_interaction = 0
		selected_coworker.set_task("meeting")
		coworker_managed = selected_coworker
		open_stress_clock(MEETING_DURATION)

func _on_Switch_item_selected(index):
	var switch = $VBoxContainer/Bottom/PanelContainer/Options/ChangeTask/ChangeTask/Switch
	if selected_coworker != null and index > 0 and index < 4:
		if index == 1:
			selected_coworker.set_task("debug")
		elif index == 2:
			selected_coworker.set_task("feature")
		elif index == 3:
			selected_coworker.set_task("documentation")
		selected_coworker.time_since_last_interaction = 0
		coworker_managed = selected_coworker
		open_stress_clock(ASSIGN_TASK_DURATION)
	switch.select(0)

func _on_Flame_button_down():
	if selected_coworker != null:
		selected_coworker.time_since_last_interaction = 0
		for coworker in coworkers_list:
			if coworker != selected_coworker:
				var rel = coworker.relationships[selected_coworker.id]
				if rel < REL_NEG_THRESHOLD and randf() < P_LIKES_FLAME:
					coworker.is_satisfied = true
					coworker.is_angry     = false
				elif rel > REL_POS_THRESHOLD and randf() < P_HATES_FLAME:
					coworker.is_satisfied = false
					coworker.is_angry     = true
		coworker_managed = selected_coworker
		open_stress_clock(FLAME_DURATION)

func _on_RedButton_gui_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		for coworker in coworkers_list:
			coworker.time_since_last_interaction = 0
			coworker.set_task("meeting")
		time_since_last_emergency_meeting = 0
		open_stress_clock(EMERGENCY_MEETING_DURATION)
	
func open_stress_clock(duration):
	var clock = $VBoxContainer/Bottom/PanelContainer/Clock
	var options = $VBoxContainer/Bottom/PanelContainer/Options
	var timer = $VBoxContainer/Bottom/PanelContainer/Clock/Timer
	options.visible = false
	clock.visible = true
	timer.wait_time = duration
	timer.start()

func _on_Timer_timeout():
	var clock = $VBoxContainer/Bottom/PanelContainer/Clock
	var options = $VBoxContainer/Bottom/PanelContainer/Options
	options.visible = true
	clock.visible = false
	if coworker_managed != null:
		coworker_managed.set_random_task()

func _on_FadeTween_tween_all_completed():
	selected_coworker = null
	
func debug_display():
	var pf = get_global_production_factor()
	print("Global production factor ", pf)
