extends SceneTree
const State = preload("res://scripts/game_state.gd")
var checks: int = 0
var failures: int = 0
var captures: int = 0
func _initialize() -> void:
    create_timer(120).timeout.connect(func(): push_error("Tempo excedido na revisão visual"); quit(1))
    call_deferred("run")
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func settle() -> void:
    for i in range(5): await process_frame
    await RenderingServer.frame_post_draw
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/10a_" + name + ".png") == OK, "Captura gravada")
    captures += 1
func layout(ui) -> void:
    var scroll = ui.pages.get_child(0)
    check(scroll.get_child(0).size.x <= scroll.size.x + 1, "Sem rolagem horizontal: " + ui.state.current_id)
    for button in ui.navigation:
        check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(button.get_global_rect()), "Navegação dentro da janela")
        check(button.get_global_rect().position.y >= ui.pages.get_global_rect().end.y - 1, "Texto não sobrepõe navegação")
func fixture(ui, id: String) -> void:
    ui.state = State.new()
    ui.state.rng.seed = 17
    ui.state.start("Leitora")
    ui.state.battle = {}
    ui.state.active_adventure = false
    ui.state.current_adventure = ""
    if id.begins_with("exam_") and id not in ["exam_invite", "exam_info"]:
        ui.state.exam = {"status":"active", "sequence":["exam_crossing", "exam_inquiry", "exam_survival", "exam_judgment"], "stage":1, "setbacks":0, "awarded":false}
        for stage in range(4):
            if id in ui.state.Exam.OPTIONS[stage]:
                ui.state.exam["stage"] = stage + 1
                ui.state.exam["sequence"][stage] = id
        if id in ["exam_pass", "exam_fail", "exam_withdraw"]:
            ui.state.exam["stage"] = 4
            ui.state.exam["status"] = {"exam_pass":"approved", "exam_fail":"failed", "exam_withdraw":"withdrawn"}[id]
    ui.state.open_event(id)
    ui.build_session()
    ui.select_tab(0)
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await settle()
    var ui = current_scene
    var ids: Array = State.new().catalog.events.keys()
    for size in [Vector2i(320,480), Vector2i(390,844)]:
        root.size = size
        for id in ids:
            fixture(ui, id)
            await settle()
            layout(ui)
            var scroll = ui.pages.get_child(0)
            check(scroll.scroll_vertical == 0, "Novo texto começa no topo")
            if size.x == 320 and id in ["exam_crossing", "exam_endurance", "exam_inquiry", "exam_capture", "exam_survival", "exam_team", "exam_duel", "exam_judgment"]:
                capture(id + "_top")
            scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
            await settle()
            if not ui.adventure_view.choice_buttons.is_empty():
                var last: Button = ui.adventure_view.choice_buttons.back()
                check(last.get_global_rect().intersects(scroll.get_global_rect()), "Última escolha alcançável: " + id)
            if size.x == 320 and id in ["exam_crossing", "exam_endurance", "exam_inquiry", "exam_capture", "exam_survival", "exam_team", "exam_duel", "exam_judgment"]:
                capture(id + "_choices")
    root.size = Vector2i(320,480)
    fixture(ui, "exam_arrival")
    ui.choose(0)
    await settle()
    check(ui.adventure_view.result_text.text.contains("até duas") and ui.adventure_view.result_text.text.contains("Fraude ou sabotagem"), "Ouvir regras apresenta critérios reais")
    var scroll = ui.pages.get_child(0)
    scroll.ensure_control_visible(ui.adventure_view.result_text)
    await settle()
    capture("rules")
    scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
    await settle()
    check(ui.adventure_view.advance_button.get_global_rect().intersects(scroll.get_global_rect()), "Continuação das regras alcançável")
    layout(ui)
    capture("rules_continue")
    ui.next_event()
    await settle()
    check(ui.pages.get_child(0).scroll_vertical == 0 and ui.state.current_id == "exam_candidates", "Continuação volta ao topo")
    print("VISUAL REVISÃO 10A: %d verificações, %d falhas, %d capturas" % [checks, failures, captures])
    quit(1 if failures else 0)
