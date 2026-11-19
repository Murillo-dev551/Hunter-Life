extends Node
signal preferences_changed
## Presentation only: no access to journey state or its RNG.
const MUSIC=preload("res://assets/audio/music/field_notes.wav")
const CUES={
    "click":preload("res://assets/audio/sfx/click.wav"),
    "select":preload("res://assets/audio/sfx/select.wav"),
    "tab":preload("res://assets/audio/sfx/tab.wav"),
    "back":preload("res://assets/audio/sfx/back.wav"),
    "success":preload("res://assets/audio/sfx/success.wav"),
    "failure":preload("res://assets/audio/sfx/failure.wav"),
    "reward":preload("res://assets/audio/sfx/reward.wav"),
    "level":preload("res://assets/audio/sfx/level.wav")}
const PRIORITY={"click":0,"tab":1,"back":1,"select":2,"success":3,"failure":3,"reward":4,"level":5}
const DEFAULTS={"music":0.22,"effects":0.5,"mute_music":false,"mute_effects":false,"reduce_motion":false}
var preferences: Dictionary=DEFAULTS.duplicate()
var config_path: String="user://audio.cfg"
var music: AudioStreamPlayer
var effects: AudioStreamPlayer
var pending: String=""
var last_cue: String=""
var save_error: Error=OK
var closing: bool=false
var fade_in: Tween
func shutdown() -> void:
    if closing:return
    closing=true;pending=""
    if fade_in and fade_in.is_valid():fade_in.kill()
    effects.stop()
    var fade=create_tween();fade.tween_property(music,"volume_db",-60.0,0.15)
    await fade.finished
    music.stop()
    # AudioServer releases playback asynchronously (Godot issue #76745).
    await get_tree().create_timer(0.15).timeout
func close_game() -> void:
    if closing:return
    await shutdown()
    get_tree().quit()
func _exit_tree() -> void:
    if is_instance_valid(music):music.stop();music.stream=null
    if is_instance_valid(effects):effects.stop();effects.stream=null
func _ready() -> void:
    get_tree().auto_accept_quit=false
    get_tree().root.close_requested.connect(close_game)
    var base=OS.get_environment("HUNTER_LIFE_DATA_ROOT")
    if base!="":config_path=base.path_join("audio.cfg")
    for bus in ["Music","Effects"]:
        if AudioServer.get_bus_index(bus)<0:
            AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
            AudioServer.set_bus_send(AudioServer.bus_count-1,"Master")
    load_preferences()
    music=AudioStreamPlayer.new();music.name="AmbientMusic";music.bus="Music";music.playback_type=AudioServer.PLAYBACK_TYPE_STREAM;add_child(music)
    var stream: AudioStreamWAV=MUSIC.duplicate()
    stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0
    stream.loop_end=int(round(stream.get_length()*stream.mix_rate))
    music.stream=stream;music.volume_db=-30
    effects=AudioStreamPlayer.new();effects.name="InterfaceEffects";effects.bus="Effects";effects.max_polyphony=1;effects.playback_type=AudioServer.PLAYBACK_TYPE_STREAM;add_child(effects)
    music.play()
    fade_in=create_tween();fade_in.tween_property(music,"volume_db",0.0,1.2)
func load_preferences() -> void:
    preferences=DEFAULTS.duplicate()
    var cfg=ConfigFile.new()
    # Parsing the text avoids engine error logs for ordinary malformed preferences.
    if FileAccess.file_exists(config_path):
        if cfg.parse(FileAccess.get_file_as_string(config_path))==OK:
            for key in DEFAULTS:
                var value=cfg.get_value("accessibility" if key=="reduce_motion" else "audio",key,DEFAULTS[key])
                if DEFAULTS[key] is bool:
                    if value is bool:preferences[key]=value
                elif (value is float or value is int) and is_finite(float(value)):
                    preferences[key]=clampf(float(value),0,1)
    apply_preferences()
    preferences_changed.emit()
func apply_preferences() -> void:
    for pair in [["Music","music"],["Effects","effects"]]:
        var index=AudioServer.get_bus_index(pair[0])
        if index<0:continue
        AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,preferences[pair[1]])))
        AudioServer.set_bus_mute(index,preferences["mute_"+pair[1]] or preferences[pair[1]]==0)
func change(key: String,value: Variant) -> void:
    if not DEFAULTS.has(key):return
    if DEFAULTS[key] is bool:
        if not value is bool:return
    else:
        if not (value is float or value is int) or not is_finite(float(value)):return
        value=clampf(float(value),0,1)
    preferences[key]=value;apply_preferences()
    preferences_changed.emit()
    var cfg=ConfigFile.new()
    for field in preferences:cfg.set_value("accessibility" if field=="reduce_motion" else "audio",field,preferences[field])
    save_error=DirAccess.make_dir_recursive_absolute(config_path.get_base_dir())
    if save_error!=OK:return
    save_error=cfg.save(config_path+".tmp")
    if save_error==OK:save_error=DirAccess.rename_absolute(config_path+".tmp",config_path)
func cue(id: String) -> void:
    if closing or not CUES.has(id):return
    if pending=="":call_deferred("flush_cue")
    if pending=="" or PRIORITY[id]>=PRIORITY[pending]:pending=id
func flush_cue() -> void:
    if pending=="":return
    last_cue=pending;pending=""
    # Coalesce same-frame UI and result notifications; one effect voice only.
    if preferences.mute_effects or preferences.effects==0:return
    effects.stop();effects.stream=CUES[last_cue];effects.play()
