extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok: failures+=1;push_error(text)
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await process_frame
    await process_frame
    var ui=current_scene
    ui.start_game("Rami")
    ui.state.open_event("offer");ui.build_session()
    for id in ["route","bridge","delivery","end_path"]:
        var index: int = 1 if ui.state.current_id=="bridge" else 0
        for i in range(ui.state.demo["choices"].size()):
            if ui.state.demo["choices"][i].has("test"): check(ui.adventure_view.choice_buttons[i].text.contains("Dificuldade"),"Teste visível antes de escolher")
        ui.choose(index)
        await process_frame
        ui.pages.get_child(0).scroll_vertical=100
        ui.next_event()
        await process_frame
        check(ui.state.current_id==id,"Sequência na interface")
        check(ui.pages.get_child(0).scroll_vertical==0,"Novo evento volta ao início")
        for tab in range(4):
            ui.select_tab(tab)
            check(ui.pages.current_tab==tab,"Navegação preservada")
        ui.select_tab(0)
    print("CONTINUIDADE UI: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures else 0)

