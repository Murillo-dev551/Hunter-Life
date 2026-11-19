extends SceneTree
const Scroll=preload("res://scripts/ui/touch_scroll.gd")
var checks=0
var failures=0
func _initialize() -> void:
    create_timer(100).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func press(position: Vector2,down: bool) -> void:
    var event=InputEventMouseButton.new();event.position=position;event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;event.pressed=down
    Input.parse_input_event(event);await process_frame
func swipe(position: Vector2,delta: Vector2) -> void:
    await press(position,true)
    for i in range(1,7):
        var motion=InputEventMouseMotion.new();motion.position=position+delta*i/6;motion.relative=delta/6;motion.button_mask=MOUSE_BUTTON_MASK_LEFT
        Input.parse_input_event(motion);await process_frame
    await press(position+delta,false);await settle()
func wheel(position: Vector2) -> void:
    var event=InputEventMouseButton.new();event.position=position;event.button_index=MOUSE_BUTTON_WHEEL_DOWN;event.pressed=true
    Input.parse_input_event(event);await settle()
func finger(position: Vector2,delta: Vector2) -> void:
    var down=InputEventScreenTouch.new();down.index=0;down.position=position;down.pressed=true;Input.parse_input_event(down);await process_frame
    if delta!=Vector2.ZERO:
        for i in range(1,7):
            var drag=InputEventScreenDrag.new();drag.index=0;drag.position=position+delta*i/6;drag.relative=delta/6;Input.parse_input_event(drag);await process_frame
    var up=InputEventScreenTouch.new();up.index=0;up.position=position+delta;up.pressed=false;Input.parse_input_event(up);await settle()
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene;var audio=root.get_node("Audio")
    root.size=Vector2i(360,780);ui.hide()
    Input.emulate_touch_from_mouse=true
    check(DisplayServer.is_touchscreen_available(),"Emulação habilita caminho nativo de toque do Godot")
    var scroll=Scroll.new();scroll.position=Vector2(20,40);scroll.size=Vector2(300,380);root.add_child(scroll)
    var column=VBoxContainer.new();scroll.add_child(column)
    var button=Button.new();button.text="Botão de teste";button.custom_minimum_size=Vector2(270,160);column.add_child(button)
    var filler=Label.new();filler.text="Linha de leitura\n".repeat(80);column.add_child(filler)
    var clicks=[0];button.pressed.connect(func():clicks[0]+=1)
    await settle()
    var start=button.get_global_rect().get_center()+Vector2(0,20)
    await swipe(start,Vector2(0,-40))
    check(scroll.scroll_vertical==0 and clicks[0]==1,"Reprodução: STOP impede arrasto e pode transformar gesto em clique")
    scroll.enable_touch_navigation();await settle();clicks[0]=0
    check(button.mouse_filter==Control.MOUSE_FILTER_PASS and scroll.scroll_deadzone==12,"Repasse nativo e zona morta explícitos")
    await swipe(start,Vector2(0,-40))
    check(scroll.scroll_vertical>0,"Arrasto iniciado no botão rola a página")
    check(clicks[0]==0,"NOTIFICATION_SCROLL_BEGIN cancela clique sem código de gesto")
    await create_timer(0.8).timeout
    scroll.scroll_vertical=0;await settle()
    await press(start,true);await press(start,false);await settle()
    check(clicks[0]==1,"Toque simples continua executando uma única ação")
    # Independent fixture: discard the preceding native kinetic-scroll state.
    column.reparent(root);scroll.free()
    scroll=Scroll.new();scroll.position=Vector2(20,40);scroll.size=Vector2(300,380);root.add_child(scroll);column.reparent(scroll);scroll.enable_touch_navigation();await settle();clicks[0]=0
    start=button.get_global_rect().get_center()+Vector2(0,20)
    var starts=[0];scroll.scroll_started.connect(func():starts[0]+=1)
    await swipe(start,Vector2(0,-4))
    check(starts[0]==0 and clicks[0]==1,"Movimento menor que a zona morta mantém o toque simples")
    scroll.scroll_vertical=200;await settle()
    var previous=scroll.scroll_vertical
    await swipe(scroll.get_global_rect().get_center(),Vector2(0,70))
    check(scroll.scroll_vertical<previous,"Arrasto para baixo retorna ao conteúdo anterior")
    await create_timer(0.8).timeout
    scroll.scroll_vertical=0;await settle();clicks[0]=0
    var touch_start=scroll.scroll_vertical
    await finger(button.get_global_rect().get_center()+Vector2(0,20),Vector2(0,-40))
    check(scroll.scroll_vertical>touch_start,"ScreenTouch/ScreenDrag reais chegam à rolagem nativa")
    check(clicks[0]==0,"Arrasto de dedo não aciona botão")
    await create_timer(0.8).timeout
    scroll.scroll_vertical=0;await settle();clicks[0]=0
    await finger(button.get_global_rect().get_center(),Vector2.ZERO)
    check(clicks[0]==1,"Toque de dedo não é duplicado pela emulação de mouse")
    Input.emulate_touch_from_mouse=false;scroll.scroll_vertical=0;await settle()
    await wheel(start);check(scroll.scroll_vertical>0,"Roda do mouse preservada")
    var dynamic=Button.new();dynamic.text="Conteúdo atualizado";column.add_child(dynamic);await settle()
    check(dynamic.mouse_filter==Control.MOUSE_FILTER_PASS,"Novos controles também recebem repasse nativo")
    scroll.queue_free();ui.show();await settle()
    ui.start_game("Rolagem");ui.state.open_event("supply_stall");ui.build_session()
    ui.state.Items.apply(ui.state,{"items_add":{"bandage":2,"medicine":1,"knife":1,"vest":1,"rope":1,"lantern":1,"map":1,"souvenir":1}})
    for i in range(30):ui.state.records.append("Registro de leitura %d." % i)
    ui.build_session();Input.emulate_touch_from_mouse=true
    var before=ui.state.serialize()
    for tab in range(4):
        ui.select_tab(tab);var page=ui.pages.get_child(tab);page.enable_touch_navigation();await settle()
        page.scroll_vertical=0;await settle()
        var point=page.get_global_rect().get_center()+Vector2(-70,30)
        await swipe(point,Vector2(0,-100))
        check(page.scroll_vertical>0,"Página rola por arrasto: "+ui.TABS[tab])
        check(before==ui.state.serialize(),"Arrasto não aciona escolhas, consumíveis, atributos ou salvamento")
    ui.state.open_event("battle_bandit");ui.state.choose(0);ui.build_session();ui.adventure_view.show_category("attack")
    var page=ui.pages.get_child(0);page.enable_touch_navigation();await settle();before=ui.state.serialize()
    await swipe(page.get_global_rect().get_center()+Vector2(-60,30),Vector2(0,-90))
    check(page.scroll_vertical>0 and ui.state.serialize()==before,"Combate rola sem consumir turno/RNG")
    ui.show_slots();page=ui.pages.get_child(0);page.enable_touch_navigation();await settle()
    await swipe(page.get_global_rect().get_center(),Vector2(0,-120))
    check(page.scroll_vertical>0,"Menu de slots também é rolável")
    ui.open_audio_settings();ui.audio_settings.scroll.enable_touch_navigation();await settle()
    check(ui.audio_settings.sliders.music.mouse_filter==Control.MOUSE_FILTER_STOP,"Slider conserva seu comportamento nativo")
    ui.audio_settings.hide()
    Input.emulate_touch_from_mouse=false
    var mode=root.mode;ui.MobileLayout.enter_immersive();check(root.mode==mode,"Modo imersivo não modifica a janela Windows")
    await audio.shutdown()
    print("TOQUE E ROLAGEM: %d verificações, %d falhas" % [checks,failures]);quit(1 if failures else 0)
