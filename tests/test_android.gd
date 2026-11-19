extends SceneTree
const Layout=preload("res://scripts/ui/mobile_layout.gd")
var checks=0
var failures=0
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
    check(not quit_on_go_back,"Voltar não encerra automaticamente")
    var insets=Layout.insets(Vector2(360,780),Rect2(0,90,1080,2130),Transform2D(Vector2(3,0),Vector2(0,3),Vector2.ZERO))
    check(insets==Vector4(0,30,0,40),"Barras físicas convertidas em margens lógicas")
    check(Layout.insets(Vector2(360,740),Rect2(0,90,1080,2220),Transform2D(Vector2(3,0),Vector2(0,3),Vector2(0,90)))==Vector4.ZERO,"Viewport já recortado não recebe margem dupla")
    ui.slot_buttons[1].create.pressed.emit();await settle()
    check(is_instance_valid(ui.creation_view),"Formulário de criação")
    ui.request_back();await settle();check(ui.pages.get_child(0).name=="Salvamentos","Voltar cancela criação sem substituir jornada")
    ui.slot_buttons[1].create.pressed.emit();await settle();ui.creation_view.name_input.text="Android";ui.creation_view.start_button.pressed.emit();await settle()
    check(ui.active_slot==1,"Criação e salvamento inicial em slot")
    var before=ui.state.serialize()
    ui.select_tab(2);ui.request_back();check(ui.current_tab==0,"Voltar retorna à Aventura")
    ui.open_audio_settings();ui.request_back();check(not ui.audio_settings.visible,"Voltar fecha configurações")
    ui.request_slot_deletion(1);ui.request_back();check(not ui.delete_dialog.visible and ui.slots.occupied(1),"Voltar cancela exclusão")
    check(before==ui.state.serialize(),"Navegação não altera RNG, escolhas ou recursos")
    audio.music.seek(8);await create_timer(0.1).timeout
    var player=audio.music
    audio.lifecycle(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
    check(player.stream_paused and not audio.effects.playing,"Áudio suspenso ao perder foco")
    audio.cue("success");check(audio.pending=="","Sem efeitos acumulados em segundo plano")
    audio.lifecycle(Node.NOTIFICATION_APPLICATION_PAUSED);audio.lifecycle(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
    check(player.stream_paused,"Foco não retoma aplicativo ainda suspenso")
    audio.lifecycle(Node.NOTIFICATION_APPLICATION_RESUMED);await settle()
    check(not player.stream_paused and audio.music==player and player.get_playback_position()>=8,"Retoma mesma música e posição")
    check(before==ui.state.serialize(),"Ciclo de vida não modifica a jornada")
    ui.state.open_event("battle_bandit");ui.build_session();ui.choose(0);await settle()
    before=ui.state.serialize();ui.adventure_view.show_category("attack");ui.request_back()
    check(ui.adventure_view.category=="" and before==ui.state.serialize(),"Voltar sai de categoria sem turno ou RNG")
    ui.request_back();await settle();check(ui.exit_dialog.visible,"Saída exige confirmação")
    ui.request_back();check(not ui.exit_dialog.visible and not audio.closing,"Cancelar saída preserva sessão")
    var pressed=[0]
    ui.settings_button.pressed.connect(func():pressed[0]+=1)
    var touch=InputEventScreenTouch.new();touch.index=0;touch.position=ui.settings_button.get_global_rect().get_center();touch.pressed=true
    Input.parse_input_event(touch);await process_frame
    var release=InputEventScreenTouch.new();release.index=0;release.position=touch.position;release.pressed=false
    Input.parse_input_event(release);await settle()
    check(pressed[0]==1 and ui.audio_settings.visible,"Toque nativo abre configurações uma única vez")
    ui.audio_settings.hide()
    for resolution in [Vector2i(360,780),Vector2i(390,845),Vector2i(480,1040)]:
        root.size=resolution;await settle()
        var bounds=Rect2(Vector2.ZERO,Vector2(resolution))
        for nav in ui.navigation:check(bounds.encloses(nav.get_global_rect()),"Abas dentro da proporção A15")
        check(bounds.encloses(ui.settings_button.get_global_rect()),"Cabeçalho alcançável")
        root.get_texture().get_image().save_png("res://tests/captures/android_combat_%d.png" % resolution.x)
        ui.request_back();await settle()
        check(ui.exit_dialog.size.x<=resolution.x and ui.exit_dialog.size.y<=resolution.y,"Confirmação de saída cabe")
        root.get_texture().get_image().save_png("res://tests/captures/android_exit_%d.png" % resolution.x)
        ui.request_back()
    # Same physical screen, canvas scaling used by the Android feature override.
    root.content_scale_size=Vector2i(360,780);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND;root.size=Vector2i(540,1170);await settle()
    check(is_equal_approx(ui.size.x,360) and is_equal_approx(ui.size.y,780),"Escala mantém dimensões lógicas na proporção 1080×2340")
    root.get_texture().get_image().save_png("res://tests/captures/android_scaled.png")
    root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED;root.content_scale_size=Vector2i.ZERO
    var token=ui.active_token;ui.active_token="invalid";ui.confirm_app_exit(true);await settle()
    check(not audio.closing and ui.exit_dialog.visible,"Falha ao salvar impede fechamento")
    ui.active_token=token;ui.state.jenny+=3
    ui.confirm_app_exit(true)
    var loaded=ui.slots.load_slot(1)
    check(loaded.error=="" and loaded.state.serialize()==ui.state.serialize(),"Salvar e sair preserva confronto, RNG e jornada")
    print("ANDROID: %d verificações, %d falhas" % [checks,failures])
    if failures:quit(1)
