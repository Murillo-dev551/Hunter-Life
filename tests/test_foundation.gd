extends SceneTree
const State = preload("res://scripts/game_state.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks += 1
    if not ok: failures += 1; push_error(text)
func run() -> void:
    var state = State.new()
    check(state.error=="" and state.catalog.events.size()==174,"Catálogo narrativo válido")
    check(not state.choose(0),"Não escolhe antes de criar personagem")
    for invalid in ["","   ","\n\t", "a".repeat(33)]: check(state.start(invalid)!="","Nome inválido recusado")
    check(state.character_name=="","Falha de nome não inicia partida")
    for i in range(3):
        check(state.start("  Liora  ")=="" and state.character_name=="Liora","Nome normalizado")
        state.open_event("market")
        check(state.attributes==State.INITIAL_ATTRIBUTES and state.attributes.size()==4,"Quatro atributos equilibrados")
        check(not state.choose(-1) and not state.choose(3),"Índice inválido recusado")
        check(state.choose(i) and state.selected_choice==i,"Cada opção tem consequência")
        check(state.records.size()==3 and state.records[-1]==state.result,"Consequência registrada")
        check(not state.choose((i+1)%3) and state.records.size()==3,"Escolha não pode ser aplicada duas vezes")
        check(state.attributes.values().all(func(v): return v>=1 and v<=10),"Atributos permanecem limitados")
    check(state.start("Outro personagem")=="" and state.selected_choice==-1 and state.records.size()==1,"Nova partida limpa demonstração anterior")
    change_scene_to_file("res://main.tscn")
    await process_frame
    await process_frame
    var ui = current_scene
    ui.show_creation()
    check(ui.creation_view!=null and ui.pages.get_child_count()==1,"Tela inicial de criação pronta")
    check(ui.navigation.all(func(b): return b.disabled),"Navegação bloqueada antes da criação")
    ui.creation_view.name_input.text="   "
    ui.creation_view.start_button.pressed.emit()
    check(ui.creation_view.feedback.visible and ui.state.character_name=="","Erro de nome contextual")
    ui.creation_view.name_input.text="Milo"
    ui.creation_view.start_button.pressed.emit()
    await process_frame
    check(ui.state.character_name=="Milo" and ui.pages.get_child_count()==4,"Sinal inicia partida com quatro abas")
    # O sorteio inicial pode ter alternativas bloqueadas; este teste cobre sinais de uma cena conhecida.
    ui.state.open_event("market");ui.build_session()
    for i in range(4):
        ui.navigation[i].pressed.emit()
        check(ui.pages.current_tab==i and ui.current_tab==i,"Sinal de navegação funcional")
    ui.navigation[0].pressed.emit()
    ui.adventure_view.choice_buttons[1].pressed.emit()
    await process_frame
    check(ui.state.selected_choice==1 and ui.adventure_view.result_text.text==ui.state.result,"Sinal exibe consequência correta")
    check(ui.adventure_view.choice_buttons.all(func(b): return b.disabled),"Escolhas resolvidas desativadas")
    ui.journal_button.pressed.emit()
    check(ui.pages.current_tab==3,"Atalho do registro funciona")
    ui.show_creation()
    await process_frame
    check(ui.state.character_name=="" and ui.pages.get_child_count()==1,"Reinício retorna à criação")
    print("FUNDAÇÃO HUNTER LIFE: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures else 0)
