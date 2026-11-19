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
    var ui=current_scene;ui.start_game("Candidata")
    ui.state.active_adventure=false;ui.state.current_adventure="";ui.state.open_event("exam_invite");ui.build_session();ui.choose(1);ui.next_event()
    ui.choose(0);ui.next_event();ui.choose(0);ui.next_event()
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size;await settle()
        check(ui.chapter.text.contains("Etapa 1/4"),"Etapa visível")
        var scroll=ui.pages.get_child(0)
        check(scroll.get_child(0).size.x<=scroll.size.x+1,"Prova não transborda")
        for b in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(b.get_global_rect()),"Navegação preservada")
        check(root.get_texture().get_image().save_png("res://tests/captures/exam_%dx%d.png" % [size.x,size.y])==OK,"Captura exame")
    ui.state.exam["stage"]=4;ui.state.exam["sequence"][3]="exam_judgment"
    ui.state.open_event("exam_judgment");ui.build_session();ui.choose(0);ui.next_event()
    root.size=Vector2i(390,844);ui.select_tab(2);await settle()
    var scroll=ui.pages.get_child(2);scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
    check(ui.state.Items.quantity(ui.state,"hunter_license")==1 and not ui.inventory_view.buttons.has("hunter_license"),"Licença visível sem botão de consumo/equipamento")
    check(root.get_texture().get_image().save_png("res://tests/captures/exam_license.png")==OK,"Captura licença")
    ui.select_tab(1);await settle()
    check(root.get_texture().get_image().save_png("res://tests/captures/exam_licensed_character.png")==OK,"Captura Hunter licenciado")
    print("VISUAL EXAME: %d verificações, %d falhas, 7 capturas" % [checks,failures])
    quit(1 if failures else 0)
