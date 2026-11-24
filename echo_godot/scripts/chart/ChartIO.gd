extends RefCounted
class_name ChartIO

static func load_chart(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        push_error("Chart não encontrado: " + path)
        return {}
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Não foi possível abrir o chart: " + path)
        return {}
    var text: String = file.get_as_text()
    var parsed: Variant = JSON.parse_string(text)
    if parsed == null or not (parsed is Dictionary):
        push_error("JSON de chart inválido: " + path)
        return {}
    return parsed as Dictionary

static func save_chart(path: String, data: Dictionary) -> bool:
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("Não foi possível salvar o chart: " + path)
        return false
    var text: String = JSON.stringify(data, "  ")
    file.store_string(text)
    return true

static func sort_notes(notes: Array) -> void:
    notes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
        return float(a.get("beat", 0.0)) < float(b.get("beat", 0.0))
    )
