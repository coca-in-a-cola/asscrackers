extends SceneTree

var failures: Array[String] = []
var count := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	count += 1
	if not condition:
		failures.append(description)
		printerr("COMPONENT FAIL: " + description)

func scenes_in(directory: String) -> Array[String]:
	var paths: Array[String] = []
	for filename in DirAccess.get_files_at(directory):
		if filename.ends_with(".tscn"):
			paths.append(directory.path_join(filename))
	for child in DirAccess.get_directories_at(directory):
		paths.append_array(scenes_in(directory.path_join(child)))
	return paths

func run() -> void:
	# Neutral host proves scenes do not require the game root or a particular parent.
	var host := Control.new()
	root.add_child(host)
	for path in scenes_in("res://scenes/ui"):
		var packed := load(path) as PackedScene
		check(packed != null, "Load " + path)
		if packed == null:
			continue
		var component := packed.instantiate()
		host.add_child(component)
		await process_frame
		check(component.is_node_ready(), "Isolated ready " + path)
		component.queue_free()
		await process_frame
	host.queue_free()
	await process_frame
	print("UI COMPONENTS: %d checks, %d failures" % [count, failures.size()])
	quit(0 if failures.is_empty() else 1)
