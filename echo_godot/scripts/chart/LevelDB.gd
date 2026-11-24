extends RefCounted
class_name LevelDB

# Cadastro das fases (uma por estação). A ORDEM desta lista é a ordem dos
# cartões na tela de seleção.
#
# Pra adicionar a música de uma fase: coloque o arquivo em
#   res://audio/music/<audio_base>.wav   (ou .ogg / .mp3)
# Nenhum código precisa ser alterado — o jogo procura as 3 extensões.
#
# "season" define a mecânica da estação (e a ferramenta do editor):
#   spring = FLOR | summer = FOGO | autumn = FOLHA | winter = GELO
#   tutorial = todas as ferramentas (pra ensinar cada mecânica)

const LEVELS: Array = [
    {
        "id": "tutorial",
        "name": "TUTORIAL",
        "lorde": "Mentor",
        "season": "tutorial",
        "difficulty": "Fácil",
        "chart": "res://charts/tutorial.json",
        "audio_base": "res://audio/music/tutorial",
    },
    {
        "id": "primavera",
        "name": "PRIMAVERA",
        "lorde": "Flora",
        "season": "spring",
        "difficulty": "Baixa",
        "chart": "res://charts/primavera.json",
        "audio_base": "res://audio/music/primavera",
    },
    {
        "id": "outono",
        "name": "OUTONO",
        "lorde": "Silas",
        "season": "autumn",
        "difficulty": "Média",
        "chart": "res://charts/outono.json",
        "audio_base": "res://audio/music/outono",
    },
    {
        "id": "verao",
        "name": "VERÃO",
        "lorde": "Solana",
        "season": "summer",
        "difficulty": "Média / Alta",
        "chart": "res://charts/sambinha_echo.json",
        "audio_base": "res://audio/music/sambinha_echo",
    },
    {
        "id": "inverno",
        "name": "INVERNO",
        "lorde": "Boreas",
        "season": "winter",
        "difficulty": "Alta",
        "chart": "res://charts/inverno.json",
        "audio_base": "res://audio/music/inverno",
    },
]

const AUDIO_EXTENSIONS: Array = ["wav", "ogg", "mp3"]

# Fase escolhida na tela de seleção (lida pelo Battle e pelo Editor).
static var selected_id: String = "verao"

static func get_level(level_id: String) -> Dictionary:
    for level in LEVELS:
        var entry: Dictionary = level
        if str(entry["id"]) == level_id:
            return entry
    return LEVELS[0] as Dictionary

static func selected() -> Dictionary:
    return get_level(selected_id)

# Caminho do áudio realmente existente da fase ("" se ainda não há música).
static func resolve_audio(level: Dictionary) -> String:
    var base: String = str(level.get("audio_base", ""))
    for ext in AUDIO_EXTENSIONS:
        var path: String = "%s.%s" % [base, str(ext)]
        if ResourceLoader.exists(path):
            return path
    return ""

# Caminho sugerido pra colocar a música (usado nas mensagens de ajuda).
static func suggested_audio_path(level: Dictionary) -> String:
    return "%s.wav" % str(level.get("audio_base", ""))

# Ferramentas especiais do editor pra cada tipo de fase (além da NOTA normal).
static func tools_for(season: String) -> Array:
    match season:
        "spring":
            return ["flower"]
        "summer":
            return ["fire"]
        "autumn":
            return ["leaf"]
        "winter":
            return ["ice"]
        "tutorial":
            return ["fire", "ice", "leaf", "flower"]
    return []

static func tool_label(tool_name: String) -> String:
    match tool_name:
        "normal":
            return "NOTA"
        "fire":
            return "FOGO"
        "ice":
            return "GELO"
        "leaf":
            return "FOLHA"
        "flower":
            return "FLOR"
    return tool_name.to_upper()

static func mechanic_text(season: String) -> String:
    match season:
        "spring":
            return "Flores desabrocham sobre as notas e escondem metade da pista. Memorize antes que cubram!"
        "summer":
            return "Notas de FOGO: não aperte! Acertar uma queima sua energia."
        "autumn":
            return "Notas-FOLHA saem voando antes de chegar. Não são erro: deixe passar."
        "winter":
            return "Notas de GELO: se apertar, as teclas vizinhas congelam por instantes."
        "tutorial":
            return "Notas, notas longas e as 4 mecânicas das estações, uma de cada vez."
    return ""
