extends SceneTree
## Can run from an absolute path against an exported pack in an empty directory.
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await create_timer(0.25).timeout
    var audio=root.get_node("Audio")
    check(audio.music.playing and audio.CUES.size()==8,"Música reproduz no pacote")
    for id in audio.CUES:check(audio.CUES[id].get_length()>0,"Efeito disponível: "+id)
    for id in ["adventure","character","inventory","record","settings","saves","attack","defend","nen","other","emblem"]:
        check(ResourceLoader.exists("res://assets/icons/"+id+".svg"),"SVG disponível: "+id)
    check(FileAccess.file_exists("res://assets/ASSET_LICENSES.md"),"Licença acompanha os recursos")
    current_scene.open_audio_settings()
    await create_timer(0.2).timeout
    check(current_scene.audio_settings.visible,"Configurações abrem no pacote")
    audio.config_path="user://test_export_audio/audio.cfg"
    current_scene.audio_settings.sliders.music.value=17
    check(is_equal_approx(audio.preferences.music,0.17) and audio.save_error==OK,"Configurações funcionam no pacote")
    await audio.shutdown()
    print("Recursos exportados: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures else 0)
