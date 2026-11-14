extends SceneTree
## Dev: why is a zone reachable at a story step? Prints the chain StoryWalk took. Usage: -- <zone> <step>
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var all := ZoneData.load_all()
	var flags := StoryWalk.story_flags()
	var step := int(a[1])
	StoryWalk.via = {}
	var r := StoryWalk.reach(all, StoryWalk.data_at(step, flags))
	var z := str(a[0])
	print("step ", step, " flag ", flags[step], " reach ", r.size(), " has ", r.has(z))
	var n := 0
	while StoryWalk.via.has(z) and n < 60:
		print(z, " <- ", StoryWalk.via[z])
		z = str(StoryWalk.via[z]).trim_prefix("from ")
		n += 1
		if z == "macclesfield":
			break
	quit()
