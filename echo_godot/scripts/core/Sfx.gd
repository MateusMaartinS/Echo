extends Node

# Autoload de efeitos sonoros.
#
#   Sfx.play("nome")  -> toca res://audio/sfx/nome.wav (ou .ogg / .mp3)
#
# Se o arquivo não existir, não acontece nada (nem erro) — então dá pra
# preparar os "ganchos" no código antes de ter os sons. É só soltar os
# arquivos em audio/sfx/ com estes nomes:
#
#   Interface (ligados AUTOMATICAMENTE em todo botão do jogo):
#     ui_hover   passar o mouse / foco do teclado sobre um botão
#     ui_click   clicar / confirmar um botão
#   Gameplay (tocados pelo Battle a cada julgamento):
#     hit_perfect, hit_good, hit_bad, miss, error,
#     fire, ice, hold_ok, hold_break
#
# O volume é controlado pelo bus "SFX" (tela de configurações).

const SFX_DIR: String = "res://audio/sfx/"
const EXTENSIONS: Array = ["wav", "ogg", "mp3"]
const VOICES: int = 8

var ui_sounds_enabled: bool = true

var _cache: Dictionary = {}
var _players: Array = []
var _next_voice: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    for i in range(VOICES):
        var voice: AudioStreamPlayer = AudioStreamPlayer.new()
        voice.bus = "SFX"
        add_child(voice)
        _players.append(voice)
    get_tree().node_added.connect(_on_node_added)

func play(sfx_name: String, volume_db: float = 0.0) -> void:
    if sfx_name == "":
        return
    var stream: AudioStream = _get_stream(sfx_name)
    if stream == null:
        return
    var voice: AudioStreamPlayer = _players[_next_voice] as AudioStreamPlayer
    _next_voice = (_next_voice + 1) % VOICES
    voice.stream = stream
    voice.volume_db = volume_db
    voice.play()

func _get_stream(sfx_name: String) -> AudioStream:
    if _cache.has(sfx_name):
        return _cache[sfx_name] as AudioStream
    var found: AudioStream = null
    for ext in EXTENSIONS:
        var path: String = "%s%s.%s" % [SFX_DIR, sfx_name, str(ext)]
        if ResourceLoader.exists(path):
            found = load(path) as AudioStream
            break
    _cache[sfx_name] = found
    return found

# --- Sons de botão (automáticos) ---------------------------------------------

func _on_node_added(node: Node) -> void:
    if node is BaseButton:
        _hook_button(node as BaseButton)

func _hook_button(button: BaseButton) -> void:
    if button.has_meta("sfx_hooked"):
        return
    button.set_meta("sfx_hooked", true)
    button.set_meta("sfx_added_ms", Time.get_ticks_msec())
    button.mouse_entered.connect(_on_button_hover.bind(button))
    button.focus_entered.connect(_on_button_focus.bind(button))
    button.pressed.connect(_on_button_pressed.bind(button))

func _on_button_hover(button: BaseButton) -> void:
    if ui_sounds_enabled and not button.disabled:
        play("ui_hover")

func _on_button_focus(button: BaseButton) -> void:
    # Ignora o foco inicial automático quando a tela acabou de abrir.
    var added_ms: int = int(button.get_meta("sfx_added_ms", 0))
    if Time.get_ticks_msec() - added_ms < 400:
        return
    if ui_sounds_enabled and not button.disabled:
        play("ui_hover")

func _on_button_pressed(_button: BaseButton) -> void:
    if ui_sounds_enabled:
        play("ui_click")
