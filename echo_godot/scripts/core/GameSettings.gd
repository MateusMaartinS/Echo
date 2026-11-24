extends Node

# Autoload: configurações do jogador. Salvas em user://settings.cfg.
#
# Cria dois "buses" de áudio na inicialização:
#   Music -> a música das fases (Conductor)
#   SFX   -> efeitos sonoros (Sfx)
# Os volumes dos dois são controlados pela tela de configurações.

const SAVE_PATH: String = "user://settings.cfg"
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

var music_volume: float = 0.8      # 0.0 a 1.0
var sfx_volume: float = 0.8        # 0.0 a 1.0
var sync_offset_ms: float = 0.0    # -150 a +150 (positivo = notas chegam mais cedo)
var fullscreen: bool = true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
    _ensure_bus(MUSIC_BUS)
    _ensure_bus(SFX_BUS)
    load_settings()
    apply_audio()

func _ensure_bus(bus_name: String) -> void:
    if AudioServer.get_bus_index(bus_name) != -1:
        return
    AudioServer.add_bus()
    var index: int = AudioServer.bus_count - 1
    AudioServer.set_bus_name(index, bus_name)
    AudioServer.set_bus_send(index, "Master")

func _apply_bus(bus_name: String, volume: float) -> void:
    var index: int = AudioServer.get_bus_index(bus_name)
    if index < 0:
        return
    AudioServer.set_bus_mute(index, volume <= 0.001)
    AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.0001)))

func apply_audio() -> void:
    _apply_bus(MUSIC_BUS, music_volume)
    _apply_bus(SFX_BUS, sfx_volume)

func set_music_volume(value: float) -> void:
    music_volume = clampf(value, 0.0, 1.0)
    _apply_bus(MUSIC_BUS, music_volume)

func set_sfx_volume(value: float) -> void:
    sfx_volume = clampf(value, 0.0, 1.0)
    _apply_bus(SFX_BUS, sfx_volume)

func set_fullscreen(value: bool) -> void:
    fullscreen = value
    if value:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func load_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    if config.load(SAVE_PATH) != OK:
        return
    music_volume = clampf(float(config.get_value("audio", "music_volume", music_volume)), 0.0, 1.0)
    sfx_volume = clampf(float(config.get_value("audio", "sfx_volume", sfx_volume)), 0.0, 1.0)
    sync_offset_ms = clampf(float(config.get_value("gameplay", "sync_offset_ms", sync_offset_ms)), -150.0, 150.0)
    if config.has_section_key("video", "fullscreen"):
        set_fullscreen(bool(config.get_value("video", "fullscreen", fullscreen)))

func save_settings() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("audio", "music_volume", music_volume)
    config.set_value("audio", "sfx_volume", sfx_volume)
    config.set_value("gameplay", "sync_offset_ms", sync_offset_ms)
    config.set_value("video", "fullscreen", fullscreen)
    var result: int = config.save(SAVE_PATH)
    if result != OK:
        push_warning("Não foi possível salvar as configurações em " + SAVE_PATH)

func reset_defaults() -> void:
    music_volume = 0.8
    sfx_volume = 0.8
    sync_offset_ms = 0.0
    apply_audio()
    save_settings()
