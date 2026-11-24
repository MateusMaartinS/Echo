extends SceneTree

# Read-only release check: every registered stage has a playable song/chart.
var failures: int = 0

func _initialize() -> void:
    call_deferred("_run")

func _expect(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error("RELEASE ASSETS: " + message)

func _run() -> void:
    for level in LevelDB.LEVELS:
        var id: String = str(level["id"])
        var chart: Dictionary = ChartIO.load_chart(str(level["chart"]))
        var song_path: String = LevelDB.resolve_audio(level)
        _expect(not chart.is_empty(),id + " chart")
        _expect(song_path != "",id + " music")
        if chart.is_empty() or song_path == "":
            continue
        var stream: AudioStream = load(song_path) as AudioStream
        _expect(stream != null,id + " audio import")
        if stream == null:
            continue
        var phrases: Array = chart.get("phrases",[])
        _expect(ChartData.count_scoring_notes(phrases) > 0,id + " playable notes")
        var final_beat: float = 0.0
        for raw in phrases:
            if raw is Dictionary:
                final_beat = maxf(final_beat,float(raw.get("end_beat",0.0)))
        var bpm: float = float(chart.get("bpm",144.0))
        var delay: float = float(chart.get("response_delay_beats",4.0))
        var final_seconds: float = (final_beat + delay) * 60.0 / bpm
        _expect(final_seconds <= stream.get_length() + .5,id + " final response exceeds audio")
        print(id,": ",ChartData.count_all_notes(phrases)," notes, ","%.1f" % final_seconds," / ","%.1f" % stream.get_length()," s")
    print("RELEASE ASSETS: ","PASS" if failures == 0 else "FAIL","; ",failures," failures")
    quit(0 if failures == 0 else 1)
