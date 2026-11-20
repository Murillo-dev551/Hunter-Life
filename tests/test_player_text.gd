extends SceneTree
const Text=preload("res://scripts/ui/player_text.gd")
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func visible_text(node: Node) -> String:
    var out: String=node.text+"\n" if node is Label or node is Button else node.get_parsed_text()+"\n" if node is RichTextLabel else ""
    for child in node.get_children():out+=visible_text(child)
    return out
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await process_frame;await process_frame
    var ui=current_scene
    ui.start_game("enemy é o nome escolhido")
    for id in Text.OUTCOMES:
        ui.state.start("Teste de textos")
        ui.state.open_event("battle_bandit");ui.state.choose(0)
        if id=="victory":ui.state.battle["hp"]=0
        if id=="incapacity":ui.state.health=0
        ui.state.Battle.finish(ui.state,id)
        for adventure in Text.ADVENTURES:ui.state.records.append("Aventura concluída: "+adventure)
        var before: Dictionary=ui.state.serialize().duplicate(true)
        ui.build_session()
        check(visible_text(ui.adventure_view).contains("Confronto encerrado: "+Text.OUTCOMES[id]),"Resultado traduzido: "+id)
        var history: String=visible_text(ui.record_content)
        for key in Text.ADVENTURES:
            check(history.contains("Aventura concluída: "+Text.ADVENTURES[key]),"Nome da aventura traduzido")
            check(not history.contains("Aventura concluída: "+key+"\n"),"ID não aparece no Registro")
        for raw in Text.OUTCOMES:check(not visible_text(ui.adventure_view).contains(raw),"Código de resultado não aparece")
        check(before==ui.state.serialize(),"Renderizar não altera dados, RNG ou recompensas")
        check(Store.save(ui.state,"user://test_player_text.json")=="","Save v7 gravado")
        var loaded: Dictionary=Store.load_state("user://test_player_text.json")
        check(loaded["error"]=="" and loaded["state"].serialize()==before,"Save v7 preserva IDs e registros antigos")
    check(Text.history("Aventura concluída: delivery")=="Aventura concluída: Entrega da Serra","Registro antigo traduzido")
    check(Text.history("Meu nome é enemy_yield.")=="Meu nome é enemy_yield.","Não substitui nomes ou texto arbitrário")
    check(Text.outcome("codigo_futuro")=="Resultado do confronto","Fallback não revela ID desconhecido")
    DirAccess.remove_absolute("user://test_player_text.json")
    print("TEXTOS: %d verificações, %d falhas" % [checks,failures])
    quit(1 if failures else 0)
