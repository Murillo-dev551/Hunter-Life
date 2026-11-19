extends SceneTree
const Motion=preload("res://scripts/ui/motion.gd")
const State=preload("res://scripts/game_state.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(100).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func fresh(event: String="market"):
    var s=State.new();s.rng.seed=42;s.start("Polimento");s.open_event(event);s.visits[event]=1;return s
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene;var audio=root.get_node("Audio")
    if OS.get_environment("HUNTER_LIFE_MOTION_EXPECT_RESTORED")=="1":check(audio.preferences.reduce_motion,"Movimento reduzido restaurado em outro processo")
    audio.change("reduce_motion",false);ui.start_game("Leitura");await settle()
    var before=ui.state.serialize();var player=audio.music
    for i in range(100):ui.select_tab(i%4)
    check(ui.current_tab==3 and ui.pages.current_tab==3,"Trocas rápidas mostram a última aba")
    check(before==ui.state.serialize(),"Transições não alteram RNG nem dados")
    var running=0
    for ref in Motion.targets:
        var control=ref.get_ref()
        if is_instance_valid(control) and control.has_meta("ui_tween") and control.get_meta("ui_tween").is_running():running+=1
    check(running<=2,"Não acumula transições nas abas ocultas")
    check(audio.music==player and player.playing,"Música não é recriada")
    var button=ui.navigation[0];button.button_down.emit()
    check(button.self_modulate!=Color.WHITE,"Pressão reconhecida imediatamente")
    button.grab_focus();check(button.has_focus(),"Botão recebe foco por teclado")
    check(button.get_theme_stylebox("focus").border_color==ui.UI.GOLD,"Foco tem borda contrastante")
    check(button.get_theme_stylebox("disabled").bg_color!=button.get_theme_stylebox("normal").bg_color,"Indisponibilidade distinta")
    audio.change("reduce_motion",true)
    check(button.self_modulate==Color.WHITE,"Ativar movimento reduzido interrompe efeitos ativos")
    ui.select_tab(0)
    check(ui.pages.get_child(0).modulate==Color.WHITE and not ui.pages.get_child(0).has_meta("ui_tween"),"Movimento reduzido usa apresentação imediata")
    audio.load_preferences();check(audio.preferences.reduce_motion,"Preferência restaurada do arquivo")
    check(not ui.state.serialize().has("reduce_motion"),"Preferência fora do save v9")
    audio.change("reduce_motion",false)
    var outcomes={}
    for seed_value in range(1,35):
        var s=fresh();s.rng.seed=seed_value;ui.state=s;ui.build_session()
        ui.choose(0);await settle()
        var key="success" if ui.last_feedback.success else "failure"
        outcomes[key]=true
        check(ui.last_feedback[key],"Feedback do teste já calculado")
        check(ui.last_feedback.xp and ui.last_feedback.money==(key=="success"),"XP e Jenny refletem apenas ganhos reais")
        var panel=ui.adventure_view.consequence.get_parent()
        check(panel.get_meta("feedback_tone")== (ui.UI.GREEN if key=="success" else ui.UI.ALERT),"Cor do resultado respeita sucesso/fracasso")
        var saved=s.serialize();var receipt=ui.last_feedback.duplicate(true)
        ui.choose(0)
        check(s.serialize()==saved and ui.last_feedback==receipt,"Clique resolvido não repete recompensas/feedback")
        ui.build_session();check(ui.last_feedback.is_empty(),"Reconstrução/carregamento não anuncia recompensa")
        if outcomes.size()==2:break
    check(outcomes.size()==2,"Sucesso e fracasso exercitados")
    var s=fresh();s.xp=39;s.rng.seed=8;ui.state=s;ui.build_session();ui.choose(0)
    check(ui.last_feedback.level and ui.last_feedback.xp,"Subida de nível e XP reconhecidos")
    s=fresh("supply_stall");ui.state=s;ui.build_session();ui.choose(0)
    check("bandage" in ui.last_feedback.items,"Aquisição real de item reconhecida")
    s=fresh();s.exam.status="approved";s.exam.stage=4;s.exam.sequence=["exam_crossing","exam_investigation","exam_survival","exam_decision"];s.selected_choice=0;s.pending_next="exam_pass";ui.state=s;ui.build_session();ui.next_event();await settle()
    check(ui.last_feedback.license and s.Items.quantity(s,"hunter_license")==1,"Licença reconhecida ao abrir o resultado do exame")
    check(ui.adventure_view.story_panel.get_meta("feedback_tone")==ui.UI.GOLD,"Licença tem realce dourado no cartão visível")
    ui.build_session();check(ui.last_feedback.is_empty(),"Licença não é anunciada ao reconstruir")
    var damage_seen=false
    var guard_seen=false
    for action in ["defend","dodge","attack","yield"]:
        s=fresh("battle_bandit");s.choose(0);s.rng.seed=8;ui.state=s;ui.build_session()
        before=s.serialize()
        for group in ui.adventure_view.GROUPS:ui.adventure_view.show_category(group)
        check(before==s.serialize(),"Categorias animadas não consomem turno ou RNG")
        ui.battle_action(action,s.battle.turn);await settle()
        check(not ui.last_feedback.is_empty(),"Resposta visual da ação "+action)
        if ui.last_feedback.damage:
            damage_seen=true
            check(ui.adventure_view.status_panel.get_meta("feedback_tone")==ui.UI.ALERT,"Dano realça a Saúde sem ocultar o resultado do teste")
        if action=="defend" and s.battle.opening or action=="dodge" and ui.last_feedback.success:guard_seen=true
        if action=="yield":check(ui.last_feedback.ended,"Encerramento reconhecido")
    check(damage_seen and guard_seen,"Dano e proteção exercitados")
    audio.change("reduce_motion",true)
    ui.state=fresh("market");ui.build_session();before=ui.state.serialize()
    ui.choose(0);await settle()
    check(not ui.adventure_view.consequence.get_parent().has_meta("ui_tween"),"Resultado estático com movimento reduzido")
    var root_path=OS.get_environment("HUNTER_LIFE_DATA_ROOT")
    check(root_path!="","Dados de teste isolados")
    ui.slots=ui.SaveSlots.new(root_path.path_join("polish_slots_"+str(Time.get_ticks_usec())))
    var slot_state=fresh();check(ui.slots.create(1,slot_state)=="","Slot ocupado de teste criado")
    DirAccess.make_dir_recursive_absolute(ui.slots.directory(3))
    FileAccess.open(ui.slots.path(3),FileAccess.WRITE).store_string("inválido")
    ui.active_slot=1;ui.active_token=ui.slots.token(1);ui.state=slot_state
    for resolution in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=resolution;ui.show_slots();await settle()
        var bounds=Rect2(Vector2.ZERO,Vector2(resolution))
        check(bounds.encloses(ui.settings_button.get_global_rect()),"Cabeçalho sem sobreposição "+str(resolution))
        check(ui.slot_buttons[1].has("load") and ui.slot_buttons[2].has("create") and ui.slot_buttons[3].load.disabled,"Estados ocupado/vazio/inválido")
        root.get_texture().get_image().save_png("res://tests/captures/10h_slots_%d.png" % resolution.x)
        ui.open_audio_settings();await settle()
        var settings_instance=ui.audio_settings;ui.open_audio_settings()
        check(settings_instance==ui.audio_settings,"Configurações reutilizam a janela")
        check(ui.audio_settings.size.x<=resolution.x and ui.audio_settings.size.y<=resolution.y,"Configurações dentro da janela")
        check(ui.audio_settings.scroll.get_v_scroll_bar().max_value<=ui.audio_settings.scroll.size.y+1,"Sem rolagem desnecessária nas configurações")
        check(ui.audio_settings.reduce_motion.button_pressed,"Movimento reduzido apresentado corretamente")
        root.get_texture().get_image().save_png("res://tests/captures/10h_settings_%d.png" % resolution.x)
        ui.audio_settings.hide()
        ui.request_slot_deletion(1);await settle();ui.delete_dialog.canceled.emit();ui.delete_dialog.hide()
        check(ui.slots.occupied(1),"Cancelar exclusão preserva a jornada")
        ui.state=fresh("market");ui.build_session();ui.choose(0);await settle()
        for nav in ui.navigation:check(bounds.encloses(nav.get_global_rect()),"Navegação inferior acessível")
        root.get_texture().get_image().save_png("res://tests/captures/10h_result_%d.png" % resolution.x)
        ui.state=fresh("battle_bandit");ui.state.choose(0);ui.build_session();ui.battle_action("defend",ui.state.battle.turn);await settle()
        root.get_texture().get_image().save_png("res://tests/captures/10h_combat_%d.png" % resolution.x)
    audio.change("reduce_motion",true);await audio.shutdown()
    print("POLIMENTO 10H: %d verificações, %d falhas" % [checks,failures]);quit(1 if failures else 0)
