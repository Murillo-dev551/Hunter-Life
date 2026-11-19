extends SceneTree
## Run as a standalone --headless --script after setting JAVA_HOME/ANDROID_HOME.
## Only editor-local paths are saved; no signing secrets enter the repository.
func _initialize() -> void:call_deferred("run")
func run() -> void:
    var path=OS.get_config_dir().path_join("Godot/editor_settings-4.7.tres")
    if not FileAccess.file_exists(path):push_error("Abra o Godot 4.7.2 uma vez para criar as preferências do editor.");quit(1);return
    var settings=ResourceLoader.load(path)
    if settings==null:push_error("Não foi possível ler as preferências locais do editor.");quit(1);return
    var java=OS.get_environment("JAVA_HOME")
    var sdk=OS.get_environment("ANDROID_HOME")
    if java=="" or sdk=="":push_error("Defina JAVA_HOME e ANDROID_HOME.");quit(1);return
    settings.set_setting("export/android/java_sdk_path",java.replace("\\","/"))
    settings.set_setting("export/android/android_sdk_path",sdk.replace("\\","/"))
    var error=ResourceSaver.save(settings,path)
    if error!=OK:push_error("Falha ao gravar configurações locais do editor.");quit(1);return
    print("Caminhos Android configurados nas preferências locais do editor.")
    quit()
