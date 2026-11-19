extends SceneTree
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
    var ui=current_scene
    ui.start_game("Confronto visual")
    var captures: int=0
    for enemy in ["bandit","fighter"]:
        ui.state.start("Confronto visual");ui.state.open_event("battle_"+enemy);ui.build_session();ui.choose(0)
        check(ui.state.Battle.active(ui.state),"Escolha real inicia confronto")
        for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
            root.size=size;await settle()
            var scroll=ui.pages.get_child(0);scroll.scroll_vertical=0;await settle()
            check(scroll.get_child(0).size.x<=scroll.size.x+1,"Combate sem transbordamento")
            for b in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(b.get_global_rect()),"Navegação preservada")
            check(root.get_texture().get_image().save_png("res://tests/captures/battle_%s_%dx%d.png" % [enemy,size.x,size.y])==OK,"Captura combate")
            captures+=1
        var before: int=ui.state.battle["turn"]
        ui.adventure_view.show_category("defend")
        ui.adventure_view.buttons["defend"].pressed.emit();await settle()
        check(ui.state.battle["turn"]==before+1,"Sinal resolve turno")
        ui.adventure_view.show_category("other");ui.adventure_view.buttons["yield"].pressed.emit();await settle()
        check(ui.state.battle["outcome"]=="yielded","Rendição pela interface")
        ui.next_event();await settle()
        check(ui.state.battle.is_empty(),"Retorno à narrativa")
    print("VISUAL BATALHA: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    quit(1 if failures else 0)
