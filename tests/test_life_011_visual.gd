extends SceneTree
const State=preload("res://scripts/game_state.gd")
var checks=0
var failures=0
func _initialize() -> void:
    create_timer(180).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func settle() -> void:
    for i in range(3):await process_frame
    await RenderingServer.frame_post_draw
func fresh():
    var s=State.new();s.rng.seed=777;s.start("Lia",0,"female")
    s.exam={"status":"approved","sequence":[s.Exam.OPTIONS[0][0],s.Exam.OPTIONS[1][0],s.Exam.OPTIONS[2][0],s.Exam.OPTIONS[3][0]],"stage":4,"setbacks":0,"awarded":true}
    s.Items.apply(s,{"items_add":{"hunter_license":1}});return s
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/011_"+name+".png")==OK,"Captura da v0.1.1")
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    ui.slots=preload("res://scripts/save_slots.gd").new("user://test_life_visual_"+str(Time.get_ticks_usec()))
    var expansion: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/journeys_011.json"))
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size
        var ids=[]
        if size.x in [320,390]:
            for event in expansion:ids.append(event.id)
        else:ids=["h_capture_offer","h_relic_trial","c_missing_route_a","011_hearing"]
        for id in ids:
            ui.state=fresh();ui.state.open_event(id);ui.build_session();await settle()
            check(ui.state.current_id==id,"Apresenta cena nova")
            var scroll=ui.pages.get_child(0)
            check(scroll.get_child(0).size.x<=scroll.size.x+1,"Texto cabe na largura")
            for button in ui.navigation:
                check(Rect2(Vector2.ZERO,Vector2(size)).encloses(button.get_global_rect()),"Abas acessíveis")
                check(button.get_global_rect().position.y>=ui.pages.get_global_rect().end.y-1,"Sem sobrepor navegação")
            if size.x==390 and id in ["h_capture_offer","h_relic_trial","c_missing_route_a"]:capture(id)
            scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
            check(ui.adventure_view.choice_buttons.back().get_global_rect().intersects(scroll.get_global_rect()),"Escolha final alcançável por rolagem")
            if size.x==320 and id=="h_relic_trial":capture("danger_choices_320")
        ui.begin_new_slot(1);await settle()
        check(is_instance_valid(ui.creation_view),"Criação com gênero acessível")
        check(ui.creation_view.gender.item_count==3,"Três opções de gênero")
        ui.creation_view.gender.select(2)
        ui.pages.get_child(0).scroll_vertical=0;await settle()
        check(Rect2(Vector2.ZERO,Vector2(size)).encloses(ui.page_title.get_global_rect()),"Cabeçalho da criação acessível")
        for button in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(size)).encloses(button.get_global_rect()),"Abas da criação dentro da tela")
        if size.x==390:capture("creation_gender")
    ui.creation_view.name_input.text="Aline";ui.create_in_slot("Aline");await settle()
    check(ui.state.gender=="female","Seleção da interface chega à lógica e ao slot")
    check(ui.slots.load_slot(1).state.gender=="female","Gênero salvo pelo fluxo real")
    ui.select_tab(1);await settle();capture("character")
    print("VISUAL VIDA 011: %d verificações, %d falhas; 82 cenas nas duas resoluções compactas e amostras em outras três" % [checks,failures])
    var audio=root.get_node("Audio");await audio.shutdown();quit(1 if failures else 0)
