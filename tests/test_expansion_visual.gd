extends SceneTree
const State=preload("res://scripts/game_state.gd")
var checks: int=0
var failures: int=0
var captures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/10b_"+name+".png")==OK,"Captura gravada")
    captures+=1
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860)]:
        root.size=size
        for id in ["escort_offer","escort_checkpoint","escort_account","ruins_offer","ruins_archive","ruins_choice","false_account"]:
            ui.state=State.new();ui.state.start("Exploradora");ui.state.battle={};ui.state.open_event(id);ui.build_session()
            await settle()
            var scroll=ui.pages.get_child(0)
            check(scroll.get_child(0).size.x<=scroll.size.x+1,"Sem transbordamento")
            for button in ui.navigation:
                check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Navegação dentro da janela")
                check(button.get_global_rect().position.y>=ui.pages.get_global_rect().end.y-1,"Navegação separada do texto")
            if size.x==390:capture(id+"_top")
            scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
            check(ui.adventure_view.choice_buttons.back().get_global_rect().intersects(scroll.get_global_rect()),"Última escolha acessível")
            if size.x==390:capture(id+"_choices")
    ui.state=State.new();ui.state.start("Exploradora");ui.state.open_event("escort_checkpoint");ui.build_session();ui.choose(3)
    await settle()
    check(ui.state.Battle.active(ui.state),"Combate aparece dentro da aventura")
    capture("escort_battle")
    print("VISUAL EXPANSÃO 10B: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    quit(1 if failures else 0)
