extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await process_frame;await process_frame
    var ui=current_scene
    ui.start_game("Distribuição")
    ui.state.Progress.award(ui.state,80)
    ui.build_session();ui.select_tab(1)
    var value: int=ui.state.attributes["strength"]
    ui.attribute_buttons["strength"].pressed.emit()
    await process_frame
    check(ui.state.attributes["strength"]==value+1 and ui.state.points==0 and ui.pages.current_tab==1,"Botão distribui ponto e mantém aba")
    check(ui.attribute_buttons.values().all(func(b):return b.disabled),"Sem pontos, botões desativados")
    ui.state.open_event("market");ui.build_session()
    check(ui.adventure_view.choice_buttons[0].text.contains("%"),"Percentual antes da escolha")
    ui.state.health=0;ui.state.active_adventure=false;ui.state.current_adventure="";ui.state.pending_next="";ui.state.selected_choice=0;ui.state.result="Jornada encerrada."
    ui.adventure_view.refresh(ui.state)
    check(ui.adventure_view.advance_button.disabled,"Saúde zero bloqueia continuar")
    print("UI PROGRESSÃO: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures else 0)
