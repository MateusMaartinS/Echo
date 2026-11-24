extends Control

# Editor por clique da fase escolhida em LevelDB.selected().
#
# - Frases: blocos de tempo do Lorde. Notas só podem ser colocadas dentro
#   do intervalo da frase selecionada.
# - Ferramentas (teclas 1..5): NOTA e as ferramentas da estação
#   (FOGO / GELO / FOLHA / FLOR; o TUTORIAL tem todas).
# - Notas longas: clique-e-arraste na lane (só com a ferramenta NOTA).
# - Flores (primavera/tutorial): arraste na trilha FLORES.
# - COPIAR / COLAR: copia a frase selecionada (ou várias em sequência) e cola
#   no playhead (COLAR AQUI) ou por cima de outro trecho (COLAR SOBRE).
# - DESFAZER (Ctrl+Z): histórico das últimas edições.
# A resposta do player é sempre gerada a partir das notas do Lorde
# deslocadas por RESPOSTA + beats.

const LEVEL_SELECT_SCENE: String = "res://scenes/LevelSelect.tscn"
const BATTLE_SCENE: String = "res://scenes/Battle.tscn"
const DEFAULT_PHRASE_LENGTH: float = 4.0
const DEFAULT_FLOWER_LENGTH: float = 2.0
const UNDO_LIMIT: int = 40
const TOOL_KEYS: Array = [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]

func _enter_tree() -> void:
	MenuMusic.stop()

var level: Dictionary = {}
var chart: Dictionary = {}
var chart_path: String = ""
var audio_stream: AudioStream = null
var phrases: Array = []
var events: Array = []
var selected_phrase_index: int = -1
var updating_fields: bool = false

# "normal" | "fire" | "ice" | "leaf" | "flower"
var current_tool: String = "normal"
var tools: Array = []                 # ferramentas especiais desta fase
var tool_order: Array = ["normal"]    # normal + especiais (ordem das teclas)
var tool_buttons: Dictionary = {}
var events_enabled: bool = false
var clear_armed: bool = false
var tool_group: ButtonGroup = ButtonGroup.new()

var undo_stack: Array = []
var last_undo_key: String = ""
var last_undo_ms: int = 0

# Área de transferência (frases copiadas, com tempos relativos ao 1º beat).
var clipboard: Array = []
var clipboard_events: Array = []
var clipboard_span: float = 0.0

@onready var timeline: Control = $TimelineScroll/TimelineView
@onready var title_label: Label = $Top/Title
@onready var bpm_spin: SpinBox = $Top/BPM
@onready var snap_spin: SpinBox = $Top/Snap
@onready var response_spin: SpinBox = $Top/ResponseDelay
@onready var status_label: Label = $Top/Status
@onready var beat_label: Label = $Top/BeatLabel
@onready var play_pause_button: Button = $Top/PlayPause
@onready var phrase_panel: Control = $PhrasePanel
@onready var phrase_list: ItemList = $PhrasePanel/PhraseList
@onready var copy_count: SpinBox = $PhrasePanel/CopyCountSpin
@onready var start_spin: SpinBox = $PhrasePanel/StartBeatSpin
@onready var end_spin: SpinBox = $PhrasePanel/EndBeatSpin
@onready var tool_title: Label = $PhrasePanel/ToolTitle
@onready var flower_half: OptionButton = $PhrasePanel/FlowerHalf
@onready var flower_field: OptionButton = $PhrasePanel/FlowerField
@onready var help_text: Label = $PhrasePanel/HelpText
@onready var clear_button: Button = $Clear

func _ready() -> void:
	level = LevelDB.selected()
	chart_path = str(level["chart"])
	var season: String = str(level["season"])
	tools = LevelDB.tools_for(season)
	events_enabled = tools.has("flower")

	var loaded: Dictionary = {}
	if FileAccess.file_exists(chart_path):
		loaded = ChartIO.load_chart(chart_path)
	if loaded.is_empty():
		loaded = ChartData.create_default(level)
	chart = ChartData.ensure_shape(loaded, level)
	phrases = chart["phrases"] as Array
	events = chart["events"] as Array

	var audio_path: String = LevelDB.resolve_audio(level)
	if audio_path != "":
		audio_stream = load(audio_path) as AudioStream

	title_label.text = "ECHO — EDITOR · %s" % str(level["name"])
	bpm_spin.value = float(chart["bpm"])
	snap_spin.value = float(chart["snap"])
	response_spin.value = float(chart["response_delay_beats"])

	Conductor.stop()
	Conductor.set_bpm(float(chart["bpm"]))
	if audio_stream != null:
		Conductor.load_stream(audio_stream)

	timeline.editor = self
	_setup_tools(season)
	_refresh_phrase_list()
	_update_selection_fields()

	if audio_stream == null:
		status_label.text = "Sem música em %s — coloque o arquivo lá pra poder tocar/sincronizar." % LevelDB.suggested_audio_path(level)
	else:
		status_label.text = "Música: %.2fs | %.2f beats | %.2f compassos | BPM %.0f" % [
			get_song_length_seconds(),
			get_song_length_beats(),
			get_song_length_beats() / 4.0,
			float(chart["bpm"])
		]

# --- Ferramentas -------------------------------------------------------------

func _setup_tools(season: String) -> void:
	tool_order = ["normal"]
	for special in tools:
		tool_order.append(special)

	var top: float = tool_title.position.y + 20.0
	for i in range(tool_order.size()):
		var tool_name: String = str(tool_order[i])
		var button: Button = Button.new()
		button.toggle_mode = true
		button.button_group = tool_group
		button.text = "%d  %s" % [i + 1, LevelDB.tool_label(tool_name)]
		button.size = Vector2(112.0, 28.0)
		button.position = Vector2(float(i % 2) * 118.0, top + floorf(float(i) / 2.0) * 32.0)
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_select_tool.bind(tool_name))
		phrase_panel.add_child(button)
		tool_buttons[tool_name] = button
	(tool_buttons["normal"] as Button).button_pressed = true

	var rows: int = int(ceil(float(tool_order.size()) / 2.0))
	var next_y: float = top + float(rows) * 32.0 + 4.0

	flower_half.clear()
	flower_half.add_item("CIMA (2 lanes de cima)")
	flower_half.add_item("BAIXO (2 lanes de baixo)")
	flower_field.clear()
	flower_field.add_item("AMBOS os campos")
	flower_field.add_item("só PLAYER")
	flower_field.add_item("só LORDE")
	flower_half.visible = events_enabled
	flower_field.visible = events_enabled
	if events_enabled:
		flower_half.position.y = next_y
		flower_field.position.y = next_y + 30.0
		next_y += 64.0

	help_text.position.y = next_y
	help_text.size.y = maxf(532.0 - next_y, 20.0)
	match season:
		"spring":
			help_text.text = "FLOR (tecla 2): arraste na trilha FLORES. Ela cobre as 2 lanes de cima ou de baixo. Clique numa flor pra apagar."
		"summer":
			help_text.text = "FOGO (tecla 2): o jogador NÃO deve apertar — apertar tira energia."
		"autumn":
			help_text.text = "FOLHA (tecla 2): sai voando antes de chegar; não é erro."
		"winter":
			help_text.text = "GELO (tecla 2): NÃO apertar — apertar congela as teclas vizinhas."
		"tutorial":
			help_text.text = "Teclas 1-5 trocam a ferramenta."
		_:
			help_text.text = ""

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var key: int = int(key_event.physical_keycode)
	if key_event.ctrl_pressed or key_event.meta_pressed:
		if key == KEY_C:
			_on_copy_pressed()
		elif key == KEY_V:
			_on_paste_here_pressed()
		elif key == KEY_Z:
			_on_undo_pressed()
		return

	for i in range(mini(TOOL_KEYS.size(), tool_order.size())):
		if key == int(TOOL_KEYS[i]):
			_select_tool(str(tool_order[i]))
			return

func _select_tool(tool_name: String) -> void:
	if not tool_buttons.has(tool_name):
		return
	current_tool = tool_name
	(tool_buttons[tool_name] as Button).button_pressed = true
	match current_tool:
		"normal":
			status_label.text = "Ferramenta NOTA: clique cria, arraste cria nota longa, clique numa nota apaga."
		"flower":
			status_label.text = "Ferramenta FLOR: arraste na trilha FLORES. Escolha CIMA/BAIXO e o campo ao lado."
		_:
			status_label.text = "Ferramenta %s: clique numa lane pra colocar (nota simples)." % LevelDB.tool_label(current_tool)

func _process(_delta: float) -> void:
	beat_label.text = "BEAT %.2f  —  %.2fs" % [Conductor.get_current_beat(), Conductor.get_song_position()]
	play_pause_button.text = "PAUSE" if Conductor.is_playing() else "PLAY"

## Duração real do áudio da fase.
func get_song_length_seconds() -> float:
	if audio_stream == null:
		return 0.0
	return maxf(audio_stream.get_length(), 0.0)

## Duração do áudio em beats, usando o BPM atual.
func get_song_length_beats() -> float:
	var duration: float = get_song_length_seconds()
	var current_bpm: float = float(bpm_spin.value)
	if duration <= 0.0 or current_bpm <= 0.0:
		return 0.0
	return duration * current_bpm / 60.0

func _on_bpm_value_changed(value: float) -> void:
	Conductor.set_bpm(value)

func _on_play_pause_pressed() -> void:
	Conductor.toggle_pause()

func _on_stop_pressed() -> void:
	Conductor.stop()

func _on_zoom_in_pressed() -> void:
	timeline.set_zoom(timeline.px_per_beat * 1.25)

func _on_zoom_out_pressed() -> void:
	timeline.set_zoom(timeline.px_per_beat * 0.8)

# --- Desfazer ------------------------------------------------------------------

func _snapshot() -> Dictionary:
	return {
		"phrases": phrases.duplicate(true),
		"events": events.duplicate(true),
		"selected": selected_phrase_index
	}

# Chame ANTES de modificar frases/notas/eventos. Com `key`, edições seguidas
# do mesmo tipo (ex.: girar a setinha do spinbox) viram um passo só.
func _push_undo(key: String = "") -> void:
	var now_ms: int = Time.get_ticks_msec()
	if key != "" and key == last_undo_key and now_ms - last_undo_ms < 800:
		last_undo_ms = now_ms
		return
	last_undo_key = key
	last_undo_ms = now_ms
	undo_stack.append(_snapshot())
	if undo_stack.size() > UNDO_LIMIT:
		undo_stack.pop_front()

func _on_undo_pressed() -> void:
	if undo_stack.is_empty():
		status_label.text = "Nada para desfazer."
		return
	var snap: Dictionary = undo_stack.pop_back()
	phrases.clear()
	for p in (snap["phrases"] as Array):
		phrases.append(p)
	events.clear()
	for e in (snap["events"] as Array):
		events.append(e)
	selected_phrase_index = int(snap["selected"])
	if selected_phrase_index >= phrases.size():
		selected_phrase_index = -1
	last_undo_key = ""
	_refresh_phrase_list()
	_update_selection_fields()
	status_label.text = "Desfeito. (%d passos restantes)" % undo_stack.size()

# --- Utilidades de grade -------------------------------------------------------

func snap_value() -> float:
	return maxf(float(snap_spin.value), 0.0625)

func snap_beat(raw_beat: float) -> float:
	var step: float = snap_value()
	return maxf(roundf(raw_beat / step) * step, 0.0)

# --- Chamadas vindas da Timeline (mouse) -----------------------------------------

func on_ruler_clicked(beat: float) -> void:
	Conductor.seek_to(Conductor.beat_to_seconds(maxf(beat, 0.0)))

# Índice da nota que "ocupa" esse ponto da lane (nota simples ou corpo de
# uma nota longa), ou -1.
func _find_note_covering(notes: Array, lane: int, raw_beat: float) -> int:
	var half_step: float = snap_value() * 0.5
	for i in range(notes.size()):
		var note: Dictionary = notes[i] as Dictionary
		if int(note.get("lane", -1)) != lane:
			continue
		var note_beat: float = float(note.get("beat", -999.0))
		var duration: float = float(note.get("duration", 0.0))
		if duration > 0.0:
			if raw_beat >= note_beat - half_step and raw_beat < note_beat + duration:
				return i
		elif absf(snap_beat(raw_beat) - note_beat) < 0.001:
			return i
	return -1

func _selected_phrase() -> Dictionary:
	if selected_phrase_index < 0 or selected_phrase_index >= phrases.size():
		return {}
	return phrases[selected_phrase_index] as Dictionary

func lane_press_is_erase(lane: int, raw_beat: float) -> bool:
	var phrase: Dictionary = _selected_phrase()
	if phrase.is_empty():
		return false
	return _find_note_covering(phrase["notes"] as Array, lane, raw_beat) >= 0

func on_lane_released(lane: int, start_raw: float, end_raw: float) -> void:
	var phrase: Dictionary = _selected_phrase()
	if phrase.is_empty():
		status_label.text = "Selecione ou crie uma frase antes de adicionar notas."
		return

	var start_beat: float = float(phrase["start_beat"])
	var end_beat: float = float(phrase["end_beat"])
	var step: float = snap_value()
	var beat: float = snap_beat(start_raw)

	if beat < start_beat - 0.001 or beat >= end_beat - 0.001:
		status_label.text = "Clique dentro do intervalo da frase selecionada (%.2f a %.2f)." % [start_beat, end_beat]
		return

	var notes: Array = phrase["notes"] as Array
	var existing_index: int = _find_note_covering(notes, lane, start_raw)
	if existing_index >= 0:
		_push_undo()
		notes.remove_at(existing_index)
		status_label.text = "Nota removida: %s (%s) no beat %.2f." % [str(Lanes.LETTERS[lane]), str(Lanes.NAMES[lane]), beat]
		_refresh_phrase_list_label(selected_phrase_index)
		return

	if current_tool == "flower":
		status_label.text = "Com a ferramenta FLOR use a trilha FLORES (acima da área do player). Pra notas, troque pra ferramenta 1."
		return

	var duration: float = 0.0
	if current_tool == "normal":
		var snapped_end: float = snap_beat(end_raw)
		# Não deixa a nota longa passar do fim da frase nem por cima da próxima nota.
		var limit: float = end_beat
		for raw_note in notes:
			var other: Dictionary = raw_note as Dictionary
			if int(other.get("lane", -1)) == lane:
				var other_beat: float = float(other.get("beat", 0.0))
				if other_beat > beat + 0.001:
					limit = minf(limit, other_beat)
		snapped_end = minf(snapped_end, limit)
		duration = snapped_end - beat
		if duration < step * 0.999:
			duration = 0.0

	_push_undo()
	var note: Dictionary = {"beat": beat, "lane": lane}
	if current_tool != "normal":
		note["type"] = current_tool
	if duration > 0.0:
		note["duration"] = duration
	notes.append(note)
	ChartIO.sort_notes(notes)

	var kind_text: String = "Nota"
	if current_tool != "normal":
		kind_text = LevelDB.tool_label(current_tool).capitalize()
	elif duration > 0.0:
		kind_text = "Nota longa (%.2f beats)" % duration
	status_label.text = "%s adicionada: %s (%s) no beat %.2f." % [kind_text, str(Lanes.LETTERS[lane]), str(Lanes.NAMES[lane]), beat]
	_refresh_phrase_list_label(selected_phrase_index)

# --- Eventos (flores da primavera) -------------------------------------------------

func _find_event_covering(raw_beat: float) -> int:
	for i in range(events.size() - 1, -1, -1):
		var ev: Dictionary = events[i] as Dictionary
		if str(ev.get("type", "")) != "flower":
			continue
		if raw_beat >= float(ev.get("start_beat", 0.0)) - 0.001 and raw_beat < float(ev.get("end_beat", 0.0)):
			return i
	return -1

func event_press_is_erase(raw_beat: float) -> bool:
	return _find_event_covering(raw_beat) >= 0

func on_event_released(start_raw: float, end_raw: float) -> void:
	if not events_enabled or current_tool != "flower":
		return

	var existing: int = _find_event_covering(start_raw)
	if existing >= 0:
		_push_undo()
		events.remove_at(existing)
		status_label.text = "Flor removida."
		return

	var step: float = snap_value()
	var start_beat: float = snap_beat(start_raw)
	var end_beat: float = snap_beat(end_raw)
	if end_beat - start_beat < step * 0.999:
		end_beat = start_beat + DEFAULT_FLOWER_LENGTH

	var half_name: String = "top" if flower_half.selected <= 0 else "bottom"
	var field_name: String = "both"
	if flower_field.selected == 1:
		field_name = "player"
	elif flower_field.selected == 2:
		field_name = "lorde"

	_push_undo()
	events.append({
		"type": "flower",
		"start_beat": start_beat,
		"end_beat": end_beat,
		"half": half_name,
		"field": field_name
	})
	_sort_events()
	status_label.text = "Flor criada: beat %.2f a %.2f (%s, %s)." % [start_beat, end_beat, half_name, field_name]

func _sort_events() -> void:
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("start_beat", 0.0)) < float(b.get("start_beat", 0.0))
	)

# --- Copiar / colar -----------------------------------------------------------------

# Índices das frases ordenados por início (a lista pode estar fora de ordem).
func _sorted_phrase_indices() -> Array:
	var order: Array = []
	for i in range(phrases.size()):
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		return float((phrases[a] as Dictionary)["start_beat"]) < float((phrases[b] as Dictionary)["start_beat"])
	)
	return order

func _on_copy_pressed() -> void:
	var phrase: Dictionary = _selected_phrase()
	if phrase.is_empty():
		status_label.text = "Selecione a frase que quer copiar (use o campo ao lado pra copiar várias em sequência)."
		return

	var order: Array = _sorted_phrase_indices()
	var position_in_order: int = order.find(selected_phrase_index)
	var count: int = int(copy_count.value)
	var base: float = float(phrase["start_beat"])

	clipboard.clear()
	clipboard_events.clear()
	clipboard_span = 0.0
	var note_total: int = 0

	for k in range(position_in_order, mini(position_in_order + count, order.size())):
		var source: Dictionary = phrases[int(order[k])] as Dictionary
		var start_off: float = float(source["start_beat"]) - base
		var end_off: float = float(source["end_beat"]) - base
		var notes_copy: Array = []
		for raw_note in (source["notes"] as Array):
			var copied: Dictionary = (raw_note as Dictionary).duplicate(true)
			copied["beat"] = float(copied.get("beat", 0.0)) - base
			notes_copy.append(copied)
		note_total += notes_copy.size()
		clipboard.append({"start_off": start_off, "end_off": end_off, "notes": notes_copy})
		clipboard_span = maxf(clipboard_span, end_off)

	# Flores que estão inteiras dentro do trecho copiado vão junto.
	for raw_event in events:
		var ev: Dictionary = raw_event as Dictionary
		if float(ev.get("start_beat", 0.0)) >= base - 0.001 and float(ev.get("end_beat", 0.0)) <= base + clipboard_span + 0.001:
			var event_copy: Dictionary = ev.duplicate(true)
			event_copy["start_beat"] = float(event_copy.get("start_beat", 0.0)) - base
			event_copy["end_beat"] = float(event_copy.get("end_beat", 0.0)) - base
			clipboard_events.append(event_copy)

	status_label.text = "Copiado: %d frase(s), %d nota(s), %d flor(es), %.2f beats. Posicione o playhead e use COLAR AQUI, ou selecione a frase de destino e use COLAR SOBRE." % [clipboard.size(), note_total, clipboard_events.size(), clipboard_span]

func _on_paste_here_pressed() -> void:
	_paste(snap_beat(Conductor.get_current_beat()), false)

func _on_paste_over_pressed() -> void:
	var phrase: Dictionary = _selected_phrase()
	if phrase.is_empty():
		status_label.text = "Selecione a frase de destino (o conteúdo copiado será colado a partir do início dela)."
		return
	_paste(float(phrase["start_beat"]), true)

func _paste(base: float, replace: bool) -> void:
	if clipboard.is_empty():
		status_label.text = "Nada copiado ainda. Selecione uma frase e clique em COPIAR."
		return

	var range_end: float = base + clipboard_span

	if not replace:
		var overlaps: int = 0
		for raw_phrase in phrases:
			var existing: Dictionary = raw_phrase as Dictionary
			if float(existing["start_beat"]) < range_end - 0.001 and float(existing["end_beat"]) > base + 0.001:
				overlaps += 1
		if overlaps > 0:
			status_label.text = "Não colei: o trecho %.2f–%.2f sobrepõe %d frase(s). Mova o playhead pra um espaço livre ou use COLAR SOBRE pra substituir." % [base, range_end, overlaps]
			return

	_push_undo()
	var removed: int = 0
	if replace:
		for i in range(phrases.size() - 1, -1, -1):
			var start_of: float = float((phrases[i] as Dictionary)["start_beat"])
			if start_of >= base - 0.001 and start_of < range_end - 0.001:
				phrases.remove_at(i)
				removed += 1
		for i in range(events.size() - 1, -1, -1):
			var event_start: float = float((events[i] as Dictionary).get("start_beat", 0.0))
			if event_start >= base - 0.001 and event_start < range_end - 0.001:
				events.remove_at(i)

	var first_new: int = phrases.size()
	var note_total: int = 0
	for entry_raw in clipboard:
		var entry: Dictionary = entry_raw as Dictionary
		var new_notes: Array = []
		for raw_note in (entry["notes"] as Array):
			var shifted: Dictionary = (raw_note as Dictionary).duplicate(true)
			shifted["beat"] = base + float(shifted.get("beat", 0.0))
			new_notes.append(shifted)
		note_total += new_notes.size()
		phrases.append({
			"start_beat": base + float(entry["start_off"]),
			"end_beat": base + float(entry["end_off"]),
			"notes": new_notes
		})
	for event_raw in clipboard_events:
		var pasted_event: Dictionary = (event_raw as Dictionary).duplicate(true)
		pasted_event["start_beat"] = base + float(pasted_event.get("start_beat", 0.0))
		pasted_event["end_beat"] = base + float(pasted_event.get("end_beat", 0.0))
		events.append(pasted_event)
	_sort_events()

	selected_phrase_index = first_new
	_refresh_phrase_list()
	_update_selection_fields()
	var replaced_text: String = ""
	if replace and removed > 0:
		replaced_text = " (substituiu %d frase(s))" % removed
	status_label.text = "Colado em %.2f: %d frase(s), %d nota(s)%s. Ctrl+Z desfaz." % [base, clipboard.size(), note_total, replaced_text]

# --- Gerenciamento de frases ---------------------------------------------

func _on_new_phrase_pressed() -> void:
	_push_undo()
	var start_beat: float = snap_beat(Conductor.get_current_beat())
	var phrase: Dictionary = {
		"start_beat": start_beat,
		"end_beat": start_beat + DEFAULT_PHRASE_LENGTH,
		"notes": []
	}
	phrases.append(phrase)
	selected_phrase_index = phrases.size() - 1
	_refresh_phrase_list()
	_update_selection_fields()
	status_label.text = "Frase criada em %.2f. Ajuste início/fim se precisar e clique nas lanes pra adicionar notas." % start_beat

func _on_delete_phrase_pressed() -> void:
	if selected_phrase_index < 0 or selected_phrase_index >= phrases.size():
		status_label.text = "Nenhuma frase selecionada."
		return
	_push_undo()
	phrases.remove_at(selected_phrase_index)
	selected_phrase_index = -1
	_refresh_phrase_list()
	_update_selection_fields()
	status_label.text = "Frase removida. (Ctrl+Z desfaz)"

func _on_phrase_list_item_selected(index: int) -> void:
	selected_phrase_index = index
	_update_selection_fields()

func _on_mark_start_pressed() -> void:
	if selected_phrase_index < 0:
		status_label.text = "Selecione uma frase primeiro."
		return
	start_spin.value = snap_beat(Conductor.get_current_beat())

func _on_mark_end_pressed() -> void:
	if selected_phrase_index < 0:
		status_label.text = "Selecione uma frase primeiro."
		return
	end_spin.value = snap_beat(Conductor.get_current_beat())

func _on_start_beat_changed(value: float) -> void:
	if updating_fields or selected_phrase_index < 0:
		return
	_push_undo("start_%d" % selected_phrase_index)
	var phrase: Dictionary = phrases[selected_phrase_index] as Dictionary
	var end_beat: float = float(phrase["end_beat"])
	if value >= end_beat:
		value = maxf(end_beat - 0.25, 0.0)
		updating_fields = true
		start_spin.value = value
		updating_fields = false
	phrase["start_beat"] = value
	_refresh_phrase_list_label(selected_phrase_index)

func _on_end_beat_changed(value: float) -> void:
	if updating_fields or selected_phrase_index < 0:
		return
	_push_undo("end_%d" % selected_phrase_index)
	var phrase: Dictionary = phrases[selected_phrase_index] as Dictionary
	var start_beat: float = float(phrase["start_beat"])
	if value <= start_beat:
		value = start_beat + 0.25
		updating_fields = true
		end_spin.value = value
		updating_fields = false
	phrase["end_beat"] = value
	_refresh_phrase_list_label(selected_phrase_index)

func _update_selection_fields() -> void:
	updating_fields = true
	var has_selection: bool = selected_phrase_index >= 0 and selected_phrase_index < phrases.size()
	start_spin.editable = has_selection
	end_spin.editable = has_selection
	if has_selection:
		var phrase: Dictionary = phrases[selected_phrase_index] as Dictionary
		start_spin.value = float(phrase["start_beat"])
		end_spin.value = float(phrase["end_beat"])
		phrase_list.select(selected_phrase_index)
	updating_fields = false

func _refresh_phrase_list() -> void:
	phrase_list.clear()
	for i in range(phrases.size()):
		phrase_list.add_item(_phrase_label(i))
	if selected_phrase_index >= 0 and selected_phrase_index < phrases.size():
		phrase_list.select(selected_phrase_index)

func _refresh_phrase_list_label(index: int) -> void:
	if index < 0 or index >= phrase_list.item_count:
		return
	phrase_list.set_item_text(index, _phrase_label(index))

func _phrase_label(index: int) -> String:
	var phrase: Dictionary = phrases[index] as Dictionary
	var notes: Array = phrase.get("notes", []) as Array
	return "Frase %d — %.2f a %.2f (%d notas)" % [index + 1, float(phrase["start_beat"]), float(phrase["end_beat"]), notes.size()]

# --- Salvar / testar / limpar / voltar -----------------------------------

func _on_save_pressed() -> void:
	var selected_ref: Variant = null
	if selected_phrase_index >= 0 and selected_phrase_index < phrases.size():
		selected_ref = phrases[selected_phrase_index]

	phrases.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("start_beat", 0.0)) < float(b.get("start_beat", 0.0))
	)

	if selected_ref != null:
		selected_phrase_index = phrases.find(selected_ref)

	var audio_path: String = LevelDB.resolve_audio(level)
	if audio_path == "":
		audio_path = LevelDB.suggested_audio_path(level)

	chart["audio"] = audio_path
	chart["bpm"] = float(bpm_spin.value)
	chart["snap"] = float(snap_spin.value)
	chart["response_delay_beats"] = float(response_spin.value)
	chart["phrases"] = phrases
	chart["events"] = events

	_refresh_phrase_list()
	_update_selection_fields()

	if ChartIO.save_chart(chart_path, chart):
		status_label.text = "Chart salvo em %s." % chart_path
	else:
		status_label.text = "ERRO ao salvar em %s (veja o Output do Godot)." % chart_path

func _on_clear_pressed() -> void:
	if not clear_armed:
		clear_armed = true
		clear_button.text = "CONFIRMAR?"
		status_label.text = "Clique em LIMPAR de novo (em até 3s) para apagar TODAS as frases e eventos desta fase."
		get_tree().create_timer(3.0).timeout.connect(_disarm_clear)
		return
	_disarm_clear()
	_push_undo()
	phrases.clear()
	events.clear()
	selected_phrase_index = -1
	_refresh_phrase_list()
	_update_selection_fields()
	status_label.text = "Tudo removido (Ctrl+Z desfaz). Salve para confirmar."

func _disarm_clear() -> void:
	clear_armed = false
	clear_button.text = "LIMPAR"

func _on_test_pressed() -> void:
	_on_save_pressed()
	Conductor.stop()
	get_tree().change_scene_to_file(BATTLE_SCENE)

func _on_back_pressed() -> void:
	Conductor.stop()
	get_tree().change_scene_to_file(LEVEL_SELECT_SCENE)
