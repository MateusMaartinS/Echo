extends Node
class_name Judge

# Resultados emitidos em `judged`:
#   Perfect / Good / Bad   -> acerto (a nota longa só "começa" aqui)
#   Miss / Error           -> nota perdida / aperto sem nota
#   HoldOK / HoldBreak     -> nota longa segurada até o fim / solta cedo
#   Fire                   -> apertou uma nota de FOGO (perde energia)
#   Ice                    -> apertou uma nota de GELO (congela vizinhas)
# Nota de FOLHA nunca gera resultado: se apertar nela, nada acontece.

signal judged(result: String, difference_ms: float, lane: int)
signal lane_frozen(lane: int, until_time: float)

@export var perfect_window: float = 0.050
@export var good_window: float = 0.100
@export var bad_window: float = 0.150
@export var miss_window: float = 0.180
# Soltar a nota longa até este tempo antes do fim ainda conta como sucesso.
@export var hold_release_tolerance: float = 0.15
# Quanto tempo (em beats) as teclas vizinhas ficam congeladas.
@export var ice_freeze_beats: float = 2.0

var player_spawner: NoteSpawner
var enabled: bool = false
var frozen_until: Array[float] = [0.0, 0.0, 0.0, 0.0]
var holding: Dictionary = {}   # lane -> RhythmNote sendo segurada

func setup(spawner: NoteSpawner) -> void:
	player_spawner = spawner

func set_enabled(value: bool) -> void:
	enabled = value

func is_lane_frozen(lane: int) -> bool:
	if lane < 0 or lane >= frozen_until.size():
		return false
	return Conductor.get_song_position() < frozen_until[lane]

func try_hit(lane: int) -> void:
	if not enabled or player_spawner == null:
		return

	var now: float = Conductor.get_song_position()

	# Tecla congelada: o aperto é simplesmente ignorado.
	if now < frozen_until[lane]:
		return

	var note: RhythmNote = player_spawner.get_best_note(lane, now, bad_window)
	if note == null:
		var pending: RhythmNote = player_spawner.get_pending_note(lane)
		var offset_ms: float = 0.0
		if pending != null:
			offset_ms = (now - pending.hit_time) * 1000.0
		judged.emit("Error", offset_ms, lane)
		return

	var difference: float = now - note.hit_time

	match note.note_type:
		"leaf":
			# Folha está indo embora: apertar não faz nada (e não pune).
			return
		"fire":
			note.mark_judged()
			judged.emit("Fire", difference * 1000.0, lane)
			return
		"ice":
			note.mark_judged()
			_freeze_neighbors(lane, now)
			judged.emit("Ice", difference * 1000.0, lane)
			return

	var result: String = "Bad"
	var absolute_difference: float = absf(difference)
	if absolute_difference <= perfect_window:
		result = "Perfect"
	elif absolute_difference <= good_window:
		result = "Good"

	if note.is_hold():
		note.begin_hold()
		holding[lane] = note
		judged.emit(result, difference * 1000.0, lane)
	else:
		note.mark_judged()
		judged.emit(result, difference * 1000.0, lane)

# Ao pausar no meio de uma nota longa: ela é encerrada sem bônus e sem punição.
func forgive_active_holds() -> void:
	for lane_key in holding.keys():
		var note: RhythmNote = _get_held(int(lane_key))
		if note != null:
			note.finish_hold()
	holding.clear()

# Chamado pelo PlayerInput quando a última tecla da lane é solta.
func try_release(lane: int) -> void:
	var note: RhythmNote = _get_held(lane)
	if note == null:
		return
	var now: float = Conductor.get_song_position()
	if now >= note.end_time - hold_release_tolerance:
		_complete_hold(note)
	else:
		_break_hold(note)

# Nota longa sendo segurada na lane (ou null). Limpa entradas inválidas.
func _get_held(lane: int) -> RhythmNote:
	if not holding.has(lane):
		return null
	var raw: Variant = holding[lane]
	if raw == null or not is_instance_valid(raw):
		holding.erase(lane)
		return null
	return raw as RhythmNote

func _complete_hold(note: RhythmNote) -> void:
	holding.erase(note.lane)
	note.finish_hold()
	judged.emit("HoldOK", 0.0, note.lane)

func _break_hold(note: RhythmNote) -> void:
	holding.erase(note.lane)
	note.break_hold()
	judged.emit("HoldBreak", 0.0, note.lane)

# "Teclas paralelas" = as lanes vizinhas (acima e abaixo) da nota de gelo.
func _freeze_neighbors(lane: int, now: float) -> void:
	var until: float = now + ice_freeze_beats * Conductor.seconds_per_beat
	for neighbor in [lane - 1, lane + 1]:
		var n: int = int(neighbor)
		if n < 0 or n >= frozen_until.size():
			continue
		frozen_until[n] = until
		lane_frozen.emit(n, until)
		# Não dá pra continuar segurando uma tecla que congelou.
		var held: RhythmNote = _get_held(n)
		if held != null:
			_break_hold(held)

func _process(_delta: float) -> void:
	if not enabled or player_spawner == null:
		return
	var now: float = Conductor.get_song_position()

	for note in player_spawner.active_notes:
		if not is_instance_valid(note) or note.judged or note.is_holding:
			continue
		var late: float = now - note.hit_time
		if late <= miss_window:
			continue
		match note.note_type:
			"normal":
				note.mark_judged()
				judged.emit("Miss", late * 1000.0, note.lane)
			_:
				# Fogo / gelo / folha que passaram sem ninguém apertar:
				# somem em silêncio, sem punição.
				note.mark_judged()

	# Notas longas seguradas até o fim completam sozinhas.
	for lane_key in holding.keys():
		var held_note: RhythmNote = _get_held(int(lane_key))
		if held_note == null:
			continue
		if now >= held_note.end_time:
			_complete_hold(held_note)
