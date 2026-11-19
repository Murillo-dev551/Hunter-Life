extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1))
    call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    ui.start_game("Personalização")
    var captures: int=0
    for pair in [["reinforce",0],["reinforce",1],["emission",0],["emission",1],["emission",2]]:
        ui.state.start("Personalização")
        ui.state.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Reforço" if pair[0]=="reinforce" else "Emissão"}
        for t in ["ten","zetsu","ren"]:ui.state.flags["nen_"+t]=true
        ui.state.open_event("develop_"+pair[0]);ui.build_session()
        ui.adventure_view.choice_buttons[pair[1]].pressed.emit()
        check(ui.state.hatsu["learned"],"Sinal desenvolve especialização")
        for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
            root.size=size;ui.select_tab(1);await settle()
            var scroll=ui.pages.get_child(1);scroll.scroll_vertical=270;await settle()
            check(scroll.get_child(0).size.x<=scroll.size.x+1,"Personagem sem transbordamento")
            check(root.get_texture().get_image().save_png("res://tests/captures/hatsu_%s_%d_%dx%d.png" % [pair[0],pair[1],size.x,size.y])==OK,"Captura Hatsu")
            captures+=1
            ui.select_tab(0);await settle()
            scroll=ui.pages.get_child(0)
            check(scroll.get_child(0).size.x<=scroll.size.x+1,"Escolhas e percentuais cabem")
            for b in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(b.get_global_rect()),"Navegação cabe")
    print("VISUAL HATSU: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    quit(1 if failures else 0)
