extends Node

# Lives across menu scene changes, but restarts after leaving gameplay/editor.
const TRACK_PATH := "res://audio/music/menu.wav"

var player: AudioStreamPlayer
var active: bool = false

func _ready() -> void:
    player = AudioStreamPlayer.new()
    player.bus = GameSettings.MUSIC_BUS
    add_child(player)
    player.finished.connect(_on_finished)
    var track := load(TRACK_PATH) as AudioStream
    if track == null:
        push_error("MenuMusic: não foi possível carregar menu.wav")
        return
    player.stream = track

func start() -> void:
    active = true
    if player.stream != null and not player.playing:
        player.play(0.0)

func stop() -> void:
    active = false
    player.stop()

func _process(_delta: float) -> void:
    if not active or player.stream == null:
        return
    # Imported compressed WAVs may never emit finished at their last sample.
    if not player.playing or player.get_playback_position() >= player.stream.get_length() - .02:
        player.play(0.0)

func _on_finished() -> void:
    if active and player.stream != null:
        player.play(0.0)
