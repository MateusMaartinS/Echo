extends Control

const ORDER := ["classic", "spring", "summer", "autumn", "winter"]
const NAMES := ["PADRÃO", "PRIMAVERA", "VERÃO", "OUTONO", "INVERNO"]
const ACCENTS := [Color("#a4bea0"),Color("#e3aec4"),BattleHudStyle.GOLD,Color("#dba67c"),Color("#83deec")]
var preview_id := ""
var selected_index := 0
var female := false
var player: SpritePlayer
var preview_vista: SeasonCardVista
var backdrop: SeasonCardVista
var preview_title: Label
var preview_stars: StarRow
var requirement: Label
var equip_button: Button
var tabs: Array[Button] = []
var tiles: Array[WardrobeSkinTile] = []
var beat := 0.0

func _ready() -> void:
	Conductor.stop()
	MenuMusic.start()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var current: String = SkinCatalog.selected_id()
	female = current.ends_with("_female")
	_build()
	_select(current)

func _process(delta: float) -> void:
	beat += delta * .8
	if player:
		player.rhythm_beat = beat

func _id(index: int) -> String:
	return ORDER[index] + ("_female" if female else "")

func _label(copy: String, pos: Vector2, dimensions: Vector2, font_size: int, color: Color, centered := false) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = pos
	label.size = dimensions
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font",BattleHudStyle.FONT)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	if centered:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

func _build() -> void:
	backdrop = SeasonCardVista.new()
	backdrop.size = Vector2(1280,720)
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.size = Vector2(1280,720)
	shade.color = Color(.055,.035,.09,.88)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	add_child(_label("VISUAIS",Vector2(34,42),Vector2(430,54),40,BattleHudStyle.CREAM))
	for i in range(2):
		var tab := Button.new()
		tab.name = "Male" if i == 0 else "Female"
		tab.text = "MASCULINO" if i == 0 else "FEMININO"
		tab.position = Vector2(486+i*370,82)
		tab.size = Vector2(354,48)
		BattleHudStyle.style_button(tab)
		tab.pressed.connect(_switch_gender.bind(i == 1))
		add_child(tab)
		tabs.append(tab)
	var panel := PixelMenuPanel.new()
	panel.name = "PreviewPanel"
	panel.position = Vector2(32,150)
	panel.size = Vector2(430,488)
	panel.edge = BattleHudStyle.GOLD
	add_child(panel)
	preview_vista = SeasonCardVista.new()
	preview_vista.name = "PreviewScenery"
	preview_vista.position = Vector2(6,6)
	preview_vista.size = Vector2(418,326)
	preview_vista.animated = true
	panel.add_child(preview_vista)
	var platform := ColorRect.new()
	platform.position = Vector2(84,309)
	platform.size = Vector2(250,8)
	platform.color = Color("#231b30")
	platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_vista.add_child(platform)
	preview_title = _label("",Vector2(16,346),Vector2(398,34),30,BattleHudStyle.CREAM,true)
	panel.add_child(preview_title)
	preview_stars = StarRow.new()
	preview_stars.name = "Stars"
	preview_stars.total = 4
	preview_stars.pixel_art = true
	preview_stars.position = Vector2(161,384)
	preview_stars.size = Vector2(108,25)
	panel.add_child(preview_stars)
	requirement = _label("",Vector2(14,413),Vector2(402,24),20,BattleHudStyle.MUTED,true)
	panel.add_child(requirement)
	equip_button = Button.new()
	equip_button.name = "Equip"
	equip_button.position = Vector2(101,443)
	equip_button.size = Vector2(228,36)
	BattleHudStyle.style_button(equip_button)
	equip_button.pressed.connect(_equip)
	panel.add_child(equip_button)
	for i in range(5):
		var tile := WardrobeSkinTile.new()
		tile.name = "Skin_"+ORDER[i]
		tile.position = Vector2(486+(i%3)*250,160+int(i/3)*222)
		tile.size = Vector2(234,204)
		add_child(tile)
		tiles.append(tile)
		tile.pressed.connect(_select_index.bind(i))
		tile.mouse_entered.connect(_select_index.bind(i))
	var footer := WardrobeControlsHint.new()
	footer.name = "ControlsHint"
	footer.position = Vector2(266,672)
	footer.size = Vector2(748,30)
	add_child(footer)

func _switch_gender(next_female: bool) -> void:
	female = next_female
	_select(_id(selected_index))

func _select_index(index: int) -> void:
	if index >= 0 and index < ORDER.size() and tiles.size() == ORDER.size():
		_select(_id(index))

func _select(skin_id: String) -> void:
	if not SkinCatalog.is_known(skin_id):
		return
	female = skin_id.ends_with("_female")
	selected_index = maxi(0,ORDER.find(skin_id.trim_suffix("_female")))
	if preview_id != skin_id:
		if player:
			preview_vista.remove_child(player)
			player.queue_free()
		player = SkinCatalog.create_player(skin_id) as SpritePlayer
		preview_vista.add_child(player)
		BattleHudStyle.fit_sprite(player,274,Vector2(209,309))
		preview_id = skin_id
	_refresh()
	if not tiles[selected_index].has_focus():
		tiles[selected_index].grab_focus()

func _refresh() -> void:
	var skin: Dictionary = SkinCatalog.get_skin(preview_id)
	var unlocked: bool = SkinCatalog.is_unlocked(preview_id)
	var current: String = SkinCatalog.selected_id()
	var accent: Color = ACCENTS[selected_index]
	var season: String = str(skin["season"])
	backdrop.season = season
	backdrop.queue_redraw()
	preview_vista.season = season
	preview_vista.queue_redraw()
	preview_title.text = NAMES[selected_index]
	preview_title.add_theme_color_override("font_color",accent)
	preview_stars.filled = float(4 if selected_index == 0 else mini(4,SkinCatalog.stars_for(preview_id)))
	preview_stars.outline_color = accent
	preview_stars.queue_redraw()
	requirement.text = "CONQUISTE 4 ESTRELAS NO " + str(LevelDB.get_level(str(skin["level"]))["name"]).to_upper() if not unlocked else ""
	equip_button.text = "EQUIPADA" if current == preview_id else "EQUIPAR"
	equip_button.disabled = not unlocked or current == preview_id
	for i in range(2):
		var active: bool = female == (i == 1)
		tabs[i].add_theme_stylebox_override("normal",BattleHudStyle.box(Color("#51405a") if active else Color("#231b30"),BattleHudStyle.GOLD if active else BattleHudStyle.MUTED,3 if active else 2))
		tabs[i].add_theme_color_override("font_color",BattleHudStyle.GOLD if active else BattleHudStyle.CREAM)
	for i in range(5):
		var item_id: String = _id(i)
		tiles[i].configure(item_id,NAMES[i],str(SkinCatalog.get_skin(item_id)["season"]),ACCENTS[i],SkinCatalog.is_unlocked(item_id),item_id == current,i == selected_index,mini(4,SkinCatalog.stars_for(item_id)))

func _equip() -> void:
	if not SkinCatalog.is_unlocked(preview_id) or preview_id == SkinCatalog.selected_id():
		return
	var result: Error = SkinCatalog.equip(preview_id)
	_refresh()
	if result != OK:
		requirement.text = "NÃO FOI POSSÍVEL SALVAR"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var next: int = selected_index
		match event.physical_keycode:
			KEY_LEFT: next = [2,0,1,4,3][selected_index]
			KEY_RIGHT: next = [1,2,0,4,3][selected_index]
			KEY_UP: next = [0,1,2,0,1][selected_index]
			KEY_DOWN: next = [3,4,4,3,4][selected_index]
			KEY_TAB:
				if event.echo:
					return
				_switch_gender(not female)
				get_viewport().set_input_as_handled()
				return
			KEY_ENTER, KEY_KP_ENTER:
				if event.echo:
					return
				_equip()
				get_viewport().set_input_as_handled()
				return
			KEY_ESCAPE:
				if event.echo:
					return
				get_viewport().set_input_as_handled()
				_back()
				return
			_: return
		_select_index(next)
		get_viewport().set_input_as_handled()

func _back() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
