extends SceneTree
## Also runs against the v0.1.1 archive for like-for-like before captures.
const State=preload("res://scripts/game_state.gd")
var checks=0
var failures=0
var baseline=false
var prefix="012_after_"
func _initialize() -> void:
    create_timer(180).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func capture(name: String) -> void:
    var folder=OS.get_environment("HUNTER_LIFE_CAPTURE_DIR")
    if folder=="":folder="res://tests/captures/"
    check(root.get_texture().get_image().save_png(folder+prefix+name+".png")==OK,"Captura gravada")
func fresh(event: String="escort_offer"):
    var s=State.new();s.rng.seed=777;s.start("Lia",0,"female");s.open_event("market")
    s.exam={"status":"approved","sequence":[s.Exam.OPTIONS[0][0],s.Exam.OPTIONS[1][0],s.Exam.OPTIONS[2][0],s.Exam.OPTIONS[3][0]],"stage":4,"setbacks":0,"awarded":true}
    s.Items.apply(s,{"items_add":{"hunter_license":1,"knife":1,"vest":1,"rope":1,"map":1,"bandage":2,"souvenir":1}})
    s.inventory.equipment.weapon="knife";s.inventory.equipment.protection="vest"
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Reforço"}
    for technique in s.nen.techniques:s.flags["nen_"+technique]=true
    s.hatsu={"learned":true,"id":"reinforce","specialization":"resistance"}
    s.level=2;s.xp=12;s.points=1;s.health=8;s.jenny=223
    s.records.append("No cais, você ajudou uma equipe a conferir a carga.\n+5 XP\n+12 Jenny")
    s.open_event(event);return s
func layout(ui) -> void:
    var bounds=Rect2(Vector2.ZERO,Vector2(root.size))
    check(bounds.encloses(ui.settings_button.get_global_rect()),"Cabeçalho acessível")
    for button in ui.navigation:check(bounds.encloses(button.get_global_rect()),"Quatro abas acessíveis")
    var scroll=ui.pages.get_child(ui.pages.current_tab)
    check(scroll.get_child(0).size.x<=scroll.size.x+1,"Sem transbordamento horizontal")
func run() -> void:
    baseline=OS.get_environment("HUNTER_LIFE_BASELINE")=="1"
    if baseline:prefix="012_before_"
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene;var audio=root.get_node("Audio")
    audio.change("reduce_motion",true)
    root.size=Vector2i(390,844);ui.state=fresh();ui.build_session();await settle()
    for tab in range(4):
        var before=ui.state.serialize().duplicate(true)
        ui.select_tab(tab);await settle();layout(ui);capture("tab_%d_390" % tab)
        check(ui.state.serialize()==before,"Apresentação não altera estado ou RNG")
    if baseline:
        print("VISUAL BASELINE 012: %d verificações, %d falhas" % [checks,failures]);await audio.shutdown();quit(1 if failures else 0);return
    var captures=["escort_offer","escort_prepare","012_inn","012_markers","012_mooring","012_window","h_relic_trial","exam_inquiry"]
    for resolution in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=resolution
        for id in captures:
            ui.state=fresh(id);var before=ui.state.serialize().duplicate(true);ui.build_session();await settle();layout(ui)
            check(ui.state.serialize()==before,"Renderização de cenário não altera RNG ou consequências")
            var scroll=ui.pages.get_child(0)
            if ui.state.demo.has("scenery"):
                check(is_instance_valid(ui.adventure_view.illustration),"Cena ilustrada possui textura")
                check(ui.adventure_view.illustration.size.y<=164.5,"Ilustração com altura responsiva limitada")
            else:check(not is_instance_valid(ui.adventure_view.illustration),"Cena textual sem espaço reservado para imagem")
            if resolution.x==390 and id in ["escort_offer","escort_prepare","012_inn"]:capture(id)
            scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
            if resolution.x==390 and id=="escort_offer":capture("escort_offer_choices")
            var prose=[]
            for node in ui.adventure_view.story_panel.get_child(0).get_children():
                if node is RichTextLabel:prose.append(node.get_parsed_text())
            check(prose==ui.state.demo.paragraphs,"Destaques editoriais conservam integralmente as palavras")
            check(ui.adventure_view.choice_buttons.back().get_global_rect().intersects(scroll.get_global_rect()),"Última escolha acessível em texto longo")
            if resolution.x==320 and id=="h_relic_trial":capture("choices_320")
        ui.state=fresh("battle_bandit");ui.state.choose(0);ui.build_session();await settle();layout(ui)
        var prior=ui.state.serialize().duplicate(true)
        for group in ui.adventure_view.GROUPS:ui.adventure_view.show_category(group);ui.adventure_view.show_category()
        check(ui.state.serialize()==prior,"Menu de combate sem turno, dano ou RNG")
        capture("battle_%d" % resolution.x)
        ui.open_audio_settings();await settle();check(ui.audio_settings.size.y<=resolution.y,"Preferências dentro da tela");ui.audio_settings.hide()
    var art=load("res://scripts/scenery.gd");var saved=art.data()["inn"].path
    art.definitions["inn"].path="res://assets/scenery/missing.webp"
    ui.state=fresh();ui.build_session();await settle()
    check(not is_instance_valid(ui.adventure_view.illustration) and ui.adventure_view.choice_buttons.size()>0,"Arte ausente preserva texto e escolhas")
    art.definitions["inn"].path=saved
    var memory_before=Performance.get_monitor(Performance.MEMORY_STATIC);var started=Time.get_ticks_msec()
    for i in range(60):
        ui.state=fresh("escort_offer" if i%2==0 else "escort_prepare");ui.build_session();await settle()
    var memory_after=Performance.get_monitor(Performance.MEMORY_STATIC)
    check(memory_after-memory_before<24*1024*1024,"Trocas não acumulam texturas ou interfaces indefinidamente")
    var metrics={"switches":60,"milliseconds":Time.get_ticks_msec()-started,"static_before":memory_before,"static_after":memory_after,"delta":memory_after-memory_before}
    FileAccess.open("res://tests/012_memory_results.json",FileAccess.WRITE).store_string(JSON.stringify(metrics,"  "))
    print("VISUAL IDENTIDADE 012: %d verificações, %d falhas; memória=%s" % [checks,failures,metrics])
    await audio.shutdown();quit(1 if failures else 0)
