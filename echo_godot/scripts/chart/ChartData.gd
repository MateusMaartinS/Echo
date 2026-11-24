extends RefCounted
class_name ChartData

# Formato do chart (JSON):
# {
#   "song_name", "audio", "bpm", "offset", "snap", "response_delay_beats",
#   "phrases": [
#     { "start_beat", "end_beat",
#       "notes": [ { "beat", "lane",
#                    "duration": beats (opcional, > 0 = nota longa),
#                    "type": "fire" | "ice" | "leaf" (opcional; padrão = normal) } ] }
#   ],
#   "events": [
#     { "type": "flower", "start_beat", "end_beat",
#       "half": "top" | "bottom", "field": "both" | "player" | "lorde" }
#   ]
# }
# Campos opcionais ausentes = comportamento antigo, então charts feitos
# antes dessa versão continuam funcionando.

static func create_default(level: Dictionary = {}) -> Dictionary:
    var audio_path: String = LevelDB.suggested_audio_path(level) if not level.is_empty() else ""
    var song_title: String = str(level.get("name", "ECHO"))
    return {
        "song_name": song_title,
        "audio": audio_path,
        "bpm": 144.0,
        "offset": 0.0,
        "snap": 0.25,
        "response_delay_beats": 4.0,
        "phrases": [],
        "events": []
    }

static func ensure_shape(data: Dictionary, level: Dictionary = {}) -> Dictionary:
    var result: Dictionary = data.duplicate(true)
    if not result.has("song_name"):
        result["song_name"] = str(level.get("name", "ECHO"))
    if not result.has("audio"):
        result["audio"] = LevelDB.suggested_audio_path(level) if not level.is_empty() else ""
    if not result.has("bpm"):
        result["bpm"] = 144.0
    if not result.has("offset"):
        result["offset"] = 0.0
    if not result.has("snap"):
        result["snap"] = 0.25
    if not result.has("response_delay_beats"):
        result["response_delay_beats"] = 4.0

    # Migração simples do formato V4: notas soltas passam a formar uma frase.
    if not result.has("phrases") or not (result["phrases"] is Array):
        result["phrases"] = []

    if (result["phrases"] as Array).is_empty() and result.has("notes") and result["notes"] is Array:
        var old_notes: Array = result["notes"] as Array
        if not old_notes.is_empty():
            var highest_beat: float = 0.0
            for raw in old_notes:
                if raw is Dictionary:
                    highest_beat = maxf(highest_beat, float((raw as Dictionary).get("beat", 0.0)))
            result["phrases"] = [{
                "start_beat": 0.0,
                "end_beat": maxf(8.0, ceilf(highest_beat + 0.01)),
                "notes": old_notes.duplicate(true)
            }]

    if not result.has("events") or not (result["events"] is Array):
        result["events"] = []

    if result.has("notes"):
        result.erase("notes")
    if result.has("phrase_beats"):
        result.erase("phrase_beats")

    return result

# Quantas notas "valem ponto" (normais, inclusive as longas). Notas de
# fogo/gelo/folha são obstáculos e não entram na conta da precisão.
static func count_scoring_notes(phrases: Array) -> int:
    var total: int = 0
    for raw_phrase in phrases:
        if not (raw_phrase is Dictionary):
            continue
        for raw_note in ((raw_phrase as Dictionary).get("notes", []) as Array):
            if raw_note is Dictionary and str((raw_note as Dictionary).get("type", "normal")) == "normal":
                total += 1
    return total

static func count_all_notes(phrases: Array) -> int:
    var total: int = 0
    for raw_phrase in phrases:
        if raw_phrase is Dictionary:
            total += ((raw_phrase as Dictionary).get("notes", []) as Array).size()
    return total
