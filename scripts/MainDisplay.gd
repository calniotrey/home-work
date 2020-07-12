extends VBoxContainer


func switch(from, to):
	$TabButtons.get_node(to).disabled = true
	$TabButtons.get_node(from).disabled = false
	
	$Graphs.get_node(to).visible = true
	$Graphs.get_node(from).visible = false


func _on_total_selected():
	switch("Diff", "Total")


func _on_diff_selected():
	switch("Total", "Diff")

