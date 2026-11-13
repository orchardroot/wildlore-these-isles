class_name ProjectTalk
extends RefCounted
## Talking about a town project: {"do": "project", "id": id} (added by TownProjects.hook after the resident's own words).
## Offers the plans, which open the "project:<id>" screen. Runs inside Commands through its host.

const OPTIONS := ["Have a look at the plans", "Not now"]

static func run(cmd: Commands, c: Dictionary) -> void:
	var host = cmd.host
	var p := TownProjects.get_project(str(c.get("id", "")))
	if p.is_empty() or TownProjects.is_done(host.data, str(p.id)):
		return
	if await host.choice(str(p.name) + "?", OPTIONS) != 0:
		return
	await host.open_menu("project:" + str(p.id))
