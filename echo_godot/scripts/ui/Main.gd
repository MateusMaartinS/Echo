extends Control

var entries: Array[TitleMenuEntry] = []
var bosses: Array[PaperMusician] = []
var selected_index: int = 0
var clock: float = 0.0

func _ready() -> void:
	Conductor.stop()
	MenuMusic.start()
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_build_menu()
	entries[0].grab_focus()

func _process(delta: float) -> void:
	clock+=delta*.45
	for boss in bosses:
		boss.rhythm_beat=clock

func _build_menu() -> void:
	var backdrop := FourSeasonsLandscape.new()
	backdrop.name="Landscape"
	backdrop.size=Vector2(1280,720)
	add_child(backdrop)
	var dim := ColorRect.new()
	dim.name="LandscapeShade"
	dim.size=Vector2(1280,720)
	dim.color=Color(.035,.025,.065,.20)
	dim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var cast := Node2D.new()
	cast.name="Bosses"
	add_child(cast)
	var seasons := ["spring","summer","autumn","winter"]
	var feet := [Vector2(156,602),Vector2(370,628),Vector2(912,628),Vector2(1136,602)]
	var heights := [286.0,336.0,336.0,286.0]
	for i in range(seasons.size()):
		var boss: PaperMusician = BossCatalog.create_lord(seasons[i])
		boss.name=str(BossCatalog.SPRITE_BOSSES[seasons[i]]["id"]).capitalize()
		cast.add_child(boss)
		if boss is SpritePlayer:
			BattleHudStyle.fit_sprite(boss as SpritePlayer,heights[i],feet[i])
		boss.modulate=Color(.78,.81,.85,.64)
		bosses.append(boss)
	var shade := ColorRect.new()
	shade.name="MenuShade"
	shade.position=Vector2(340,230)
	shade.size=Vector2(600,430)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader=preload("res://shaders/title_menu_shade.gdshader")
	shade.material=material
	add_child(shade)
	var logo := EchoTitleLogo.new()
	logo.name="Logo"
	logo.position=Vector2(402,64)
	logo.size=Vector2(476,140)
	add_child(logo)
	var titles := ["JOGAR","PERSONAGENS","EDITOR","CONFIGURAÇÕES","SAIR"]
	var names := ["Play","Wardrobe","Editor","Settings","Quit"]
	var actions: Array[Callable] = [_on_play_pressed,_on_wardrobe_pressed,_on_editor_pressed,_on_settings_pressed,_on_quit_pressed]
	for i in range(titles.size()):
		var entry := TitleMenuEntry.new()
		entry.name=names[i]
		entry.text=titles[i]
		entry.position=Vector2(476,286+i*58)
		entry.size=Vector2(340,48)
		entry.pressed.connect(actions[i])
		add_child(entry)
		entries.append(entry)
		entry.focus_entered.connect(_select.bind(i))
		entry.mouse_entered.connect(_focus_entry.bind(i))
	for i in range(entries.size()):
		var entry: TitleMenuEntry = entries[i]
		entry.focus_neighbor_top=entry.get_path_to(entries[(i-1+entries.size())%entries.size()])
		entry.focus_neighbor_bottom=entry.get_path_to(entries[(i+1)%entries.size()])
	var hint := TitleControlsHint.new()
	hint.name="ControlsHint"
	hint.position=Vector2(343,668)
	hint.size=Vector2(594,30)
	add_child(hint)

func _select(index: int) -> void:
	selected_index=index
	for i in range(entries.size()):
		entries[i].active=i==index

func _focus_entry(index: int) -> void:
	if index >= 0 and index < entries.size():
		entries[index].grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		# The title is the root screen: Back restores its first option.
		entries[0].grab_focus()

func _on_play_pressed() -> void:
	EchoLevelSelect.developer_mode = false
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_editor_pressed() -> void:
	EchoLevelSelect.developer_mode = true
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_wardrobe_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Wardrobe.tscn")
