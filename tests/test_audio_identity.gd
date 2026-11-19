extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Icons=preload("res://scripts/ui/line_icon.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene;var audio=root.get_node("Audio")
    var original_path: String=audio.config_path
    if OS.get_environment("HUNTER_LIFE_AUDIO_EXPECT_RESTORED")=="1":
        check(is_equal_approx(audio.preferences.music,0.29) and is_equal_approx(audio.preferences.effects,0.42) and audio.preferences.mute_music and not audio.preferences.mute_effects,"Preferências restauradas em outro processo")
    audio.config_path=OS.get_environment("HUNTER_LIFE_DATA_ROOT").path_join("audio_test.cfg")
    check(audio.music.playing and audio.music.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Música em reprodução e loop")
    check(audio.music.stream.get_length()==64,"Faixa original de 64 segundos")
    check(audio.get_children().size()==2 and audio.effects.max_polyphony==1,"Uma música e uma voz de efeitos")
    check(audio.config_path!=ui.slots.legacy,"Preferências fora dos slots")
    for cue in audio.CUES:
        audio.cue(cue);await settle()
        check(audio.last_cue==cue and audio.effects.stream==audio.CUES[cue],"Reprodução do efeito "+cue)
    audio.cue("click");audio.cue("level");audio.cue("select");await settle()
    check(audio.last_cue=="level","Aviso prioritário evita sobreposição")
    audio.change("music",0.37);audio.change("effects",0.64)
    audio.change("mute_music",true);audio.change("mute_effects",true)
    check(audio.save_error==OK,"Preferências salvas")
    audio.load_preferences()
    check(audio.preferences.music==0.37 and audio.preferences.effects==0.64,"Volumes persistentes")
    for channel in ["Music","Effects"]:check(AudioServer.is_bus_mute(AudioServer.get_bus_index(channel)),"Silenciar "+channel)
    check(audio.music.playing,"Silenciar preserva a reprodução")
    audio.change("mute_music",false);audio.change("mute_effects",false)
    for channel in ["Music","Effects"]:check(not AudioServer.is_bus_mute(AudioServer.get_bus_index(channel)),"Restaurar "+channel)
    var cfg=ConfigFile.new();cfg.set_value("audio","music",-5);cfg.set_value("audio","effects","alto");cfg.set_value("audio","mute_music",7);cfg.save(audio.config_path)
    audio.load_preferences()
    check(audio.preferences.music==0 and audio.preferences.effects==0.5 and audio.preferences.mute_music==false,"Tipos inválidos e volumes fora da faixa")
    cfg.set_value("audio","music",NAN);cfg.set_value("audio","effects",INF);cfg.save(audio.config_path);audio.load_preferences()
    check(audio.preferences.music==audio.DEFAULTS.music and audio.preferences.effects==audio.DEFAULTS.effects,"NaN e infinito usam valores seguros")
    FileAccess.open(audio.config_path,FileAccess.WRITE).store_string("arquivo inválido")
    audio.load_preferences();check(audio.preferences==audio.DEFAULTS,"Arquivo inválido usa padrões seguros")
    DirAccess.remove_absolute(audio.config_path);audio.load_preferences()
    check(audio.preferences==audio.DEFAULTS,"Arquivo ausente usa padrões")
    for key in ["music","effects"]:
        audio.change(key,0.42);audio.change("mute_"+key,true)
    ui.open_audio_settings();await settle()
    check(ui.audio_settings.sliders.size()==2 and ui.audio_settings.mutes.size()==2,"Controles independentes de áudio")
    ui.audio_settings.sliders.music.value=29
    check(is_equal_approx(audio.preferences.music,0.29),"Slider aplica imediatamente")
    ui.audio_settings.mutes.effects.button_pressed=false
    check(not audio.preferences.mute_effects,"Controle de efeitos aplica imediatamente")
    ui.audio_settings.hide()
    ui.start_game("Áudio");await settle()
    var before=ui.state.serialize();var player=audio.music
    player.seek(15);await create_timer(0.1).timeout
    for tab in range(4):ui.navigation[tab].pressed.emit();await settle()
    check(before==ui.state.serialize(),"Abas e sons não alteram a jornada ou RNG")
    check(audio.music==player and player.playing,"Navegação preserva o único reprodutor")
    check(player.get_playback_position()>=15,"Trocar de aba não reinicia a faixa")
    check(audio.last_cue=="tab","Mudança de aba tem efeito próprio")
    for text in ["· sucesso","· fracasso"]:
        ui.result_sound([ui.state.level,ui.state.xp,ui.state.jenny],text);await settle()
        check(audio.last_cue==("success" if "sucesso" in text else "failure"),"Efeito do resultado d20")
    ui.result_sound([ui.state.level,ui.state.xp,ui.state.jenny-1],"");await settle();check(audio.last_cue=="reward","Efeito de recompensa")
    ui.result_sound([ui.state.level-1,ui.state.xp,ui.state.jenny],"");await settle();check(audio.last_cue=="level","Efeito de nível")
    var s=State.new();s.rng.seed=9;s.start("Combate");s.open_event("battle_bandit");s.choose(0);ui.state=s;ui.build_session();await settle()
    before=s.serialize()
    for group in ui.adventure_view.GROUPS:
        ui.adventure_view.show_category(group);await settle();ui.adventure_view.show_category();await settle()
    check(before==s.serialize(),"Navegação e áudio do combate não consomem RNG/turnos")
    root.get_texture().get_image().save_png("res://tests/captures/10g_combat.png")
    for id in Icons.TEXTURES:check(Icons.TEXTURES[id]!=null,"Ícone local exportável "+id)
    audio.music.seek(63.85);await create_timer(0.45).timeout
    check(audio.music.playing and audio.music.get_playback_position()<1,"Loop atravessa o fim sem parar")
    for resolution in [Vector2i(320,480),Vector2i(480,860),Vector2i(960,720)]:
        root.size=resolution;ui.show_slots();await settle()
        check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(ui.settings_button.get_global_rect()),"Configurações no cabeçalho "+str(resolution))
        root.get_texture().get_image().save_png("res://tests/captures/10g_slots_%d.png" % resolution.x)
        ui.open_audio_settings();await settle()
        check(ui.audio_settings.size.x<=root.size.x and ui.audio_settings.size.y<=root.size.y,"Diálogo compacto "+str(resolution))
        root.get_texture().get_image().save_png("res://tests/captures/10g_settings_%d.png" % resolution.x)
        ui.audio_settings.hide()
    audio.config_path=original_path
    audio.change("music",0.29);audio.change("effects",0.42);audio.change("mute_music",true);audio.change("mute_effects",false)
    await audio.shutdown()
    check(not audio.music.playing and not audio.effects.playing,"Encerramento suave libera reprodutores")
    print("Áudio e identidade: %d verificações, %d falhas" % [checks,failures]);quit(1 if failures else 0)
