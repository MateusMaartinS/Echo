extends Node
class_name ECHOConductor

signal beat_changed(beat: int)
signal song_started
signal song_finished

var bpm: float = 144.0
var seconds_per_beat: float = 60.0 / 144.0
var song_position: float = 0.0
var current_beat: int = -1
var running: bool = false

var capture: AudioEffectCapture
var recent_audio: PackedVector2Array = PackedVector2Array()
var rewind_player: AudioStreamPlayer

var player: AudioStreamPlayer

# Ajuste de sincronia (segundos) das configurações do jogador. Só é aplicado
# durante a partida (o Battle liga; stop() zera), pra nunca afetar o editor.
var offset_seconds: float = 0.0

func _ready() -> void:
    player = AudioStreamPlayer.new()
    player.bus = "Music"   # bus criado pelo autoload GameSettings (volume da música)
    add_child(player)
    process_mode = Node.PROCESS_MODE_ALWAYS
    capture = AudioEffectCapture.new()
    capture.buffer_length = 1.0
    AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), capture)
    rewind_player = AudioStreamPlayer.new()
    rewind_player.bus = "SFX"
    add_child(rewind_player)

# O jogo abre em tela cheia (ver project.godot). F11 alterna pra janela,
# útil durante o desenvolvimento. Fica aqui porque o Conductor é autoload
# e existe em todas as cenas (Main, Editor, Battle).
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if (event as InputEventKey).physical_keycode == KEY_F11:
            _toggle_fullscreen()

func _toggle_fullscreen() -> void:
    if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_bpm(new_bpm: float) -> void:
    bpm = maxf(new_bpm, 1.0)
    seconds_per_beat = 60.0 / bpm

func play_stream(stream: AudioStream, from_position: float = 0.0) -> void:
    if stream == null:
        push_error("Conductor: áudio nulo.")
        return
    player.stream_paused = false
    recent_audio.clear()
    capture.clear_buffer()
    player.stream = stream
    player.play(from_position)
    song_position = from_position
    current_beat = int(floor(song_position / seconds_per_beat)) - 1
    running = true
    song_started.emit()

func stop() -> void:
    player.stop()
    offset_seconds = 0.0
    running = false
    song_position = 0.0
    current_beat = -1

func pause() -> void:
    player.stream_paused = true

func resume() -> void:
    player.stream_paused = false

func is_playing() -> bool:
    return running and player.playing and not player.stream_paused

# --- Editor-oriented helpers -------------------------------------------
# These are used by ChartEditor so it can preview/seek without needing a
# strict "play from the start" flow like gameplay does.

## Loads a stream without starting playback (used so the editor can seek
## into it before the user presses PLAY).
func load_stream(stream: AudioStream) -> void:
    if stream == null:
        return
    if player.stream != stream:
        player.stream = stream
        song_position = 0.0
        current_beat = -1

## Moves the playhead to an exact time, whether currently playing, paused
## or stopped. Restarts playback internally (Godot's documented way to set
## a stream position) and immediately re-pauses if it wasn't audibly
## playing before, so there may be a single-frame audio blip when seeking
## while paused. Acceptable trade-off for an editor scrub bar.
func seek_to(seconds: float) -> void:
    if player.stream == null:
        return
    seconds = maxf(seconds, 0.0)
    var was_audible: bool = player.playing and not player.stream_paused
    player.play(seconds)
    if not was_audible:
        player.stream_paused = true
    song_position = seconds
    current_beat = int(floor(song_position / seconds_per_beat)) - 1
    running = true

## Starts playback from the current song_position if stopped, otherwise
## flips the paused flag. Meant for a single PLAY/PAUSE toggle button.
func toggle_pause() -> void:
    if player.stream == null:
        return
    if not player.playing:
        player.play(song_position)
        player.stream_paused = false
        running = true
        return
    player.stream_paused = not player.stream_paused

func get_song_position() -> float:
    return song_position

func get_current_beat() -> float:
    return song_position / seconds_per_beat

func beat_to_seconds(beat: float, offset: float = 0.0) -> float:
    return (beat * seconds_per_beat) + offset

func seconds_to_beat(seconds: float, offset: float = 0.0) -> float:
    return (seconds - offset) / seconds_per_beat

func _process(_delta: float) -> void:
    var samples: PackedVector2Array = capture.get_buffer(capture.get_frames_available())
    if running and player.playing and not player.stream_paused:
        recent_audio.append_array(samples)
        var limit: int = int(AudioServer.get_mix_rate() * 0.55)
        if recent_audio.size() > limit:
            recent_audio = recent_audio.slice(recent_audio.size() - limit)
    if not running:
        return
    if player.stream == null:
        return
    if not player.playing and not player.stream_paused:
        running = false
        song_finished.emit()
        return

    # Pausado: a posição fica congelada (nem o "tremido" de get_time_since_last_mix).
    if player.stream_paused:
        return

    var pos: float = player.get_playback_position()
    pos += AudioServer.get_time_since_last_mix()
    pos -= AudioServer.get_output_latency()
    pos += offset_seconds
    song_position = maxf(pos, 0.0)

    var new_beat: int = int(floor(song_position / seconds_per_beat))
    if new_beat != current_beat:
        current_beat = new_beat
        beat_changed.emit(current_beat)

# Short reversed excerpt; never seeks or advances the gameplay clock.
func rewind_preview() -> void:
    if recent_audio.is_empty():
        await get_tree().process_frame
        return
    var pcm: PackedByteArray = PackedByteArray()
    var frames: int = recent_audio.size()
    pcm.resize(frames * 4)
    for i in range(frames):
        var sample: Vector2 = recent_audio[frames - 1 - i]
        var envelope: float = minf(float(i) / 600.0, 1.0) * minf(float(frames - 1 - i) / 2000.0, 1.0)
        pcm.encode_s16(i * 4, int(clampf(sample.x * envelope, -1.0, 1.0) * 32767.0))
        pcm.encode_s16(i * 4 + 2, int(clampf(sample.y * envelope, -1.0, 1.0) * 32767.0))
    var excerpt: AudioStreamWAV = AudioStreamWAV.new()
    excerpt.format = AudioStreamWAV.FORMAT_16_BITS
    excerpt.stereo = true
    excerpt.mix_rate = int(AudioServer.get_mix_rate())
    excerpt.data = pcm
    rewind_player.stream = excerpt
    rewind_player.volume_db = -9.0
    rewind_player.pitch_scale = 1.4
    rewind_player.play()
    var tween: Tween = create_tween().set_parallel(true)
    tween.tween_property(rewind_player, "pitch_scale", 0.65, 0.55)
    tween.tween_property(rewind_player, "volume_db", -40.0, 0.55)
    await tween.finished
    rewind_player.stop()
