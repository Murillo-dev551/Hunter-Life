extends VBoxContainer
signal continue_requested
signal action_requested(id: String, token: int)
signal record_requested
const UI=preload("res://scripts/ui/styles.gd")
const PlayerText=preload("res://scripts/ui/player_text.gd")
var buttons: Dictionary={}
func build(state) -> void:
    var b: Dictionary=state.battle
    var card=UI.card(self)
    card.add_child(UI.label(state.Battle.ENEMIES[b["enemy"]]["name"],22,UI.GREEN))
    card.add_child(UI.label(state.Battle.ENEMIES[b["enemy"]]["description"],14))
    card.add_child(UI.label("Sua Saúde: %d/10 · Adversário: %d/%d\nTurno %d" % [state.health,b["hp"],state.Battle.ENEMIES[b["enemy"]]["hp"],b["turn"]],16))
    if not b["log"].is_empty():
        var last=UI.card(self);last.add_child(UI.label("\n".join(b["log"].slice(-2)) if b["outcome"]!="" else b["log"][-1],15,UI.ALERT if state.health<=3 else UI.INK))
    if state.Battle.active(state):
        add_child(UI.label("Intenção: "+state.Battle.INTENTS[b["intent"]],16,UI.GREEN))
        if b["opening"]:add_child(UI.label("Você tem uma abertura para contra-atacar.",14))
        for id in state.Battle.LABELS:
            if id in ["ten","zetsu","ren"] and id not in state.nen["techniques"]:continue
            if id=="hatsu" and not state.hatsu["learned"]:continue
            var text: String=state.Battle.LABELS[id]
            if id=="hatsu":text=state.Hatsu.NAMES[state.hatsu["id"]]+" · "+state.Hatsu.LABELS[state.hatsu["specialization"]]
            var test: Dictionary=state.Battle.test(state,id)
            if not test.is_empty():text+="\n%s · Dif. %d · %d%%" % [state.ATTRIBUTE_NAMES[test["attribute"]],test["difficulty"],state.Progress.chance(state.attributes[test["attribute"]],test["difficulty"])]
            var button=UI.button(text,id=="attack")
            button.add_theme_font_size_override("font_size",14)
            button.custom_minimum_size.y=76 if not test.is_empty() else 52
            button.disabled=state.Battle.reason(state,id)!="";button.tooltip_text=state.Battle.reason(state,id)
            var token: int=b["turn"]
            button.pressed.connect(func():action_requested.emit(id,token))
            add_child(button);buttons[id]=button
    else:
        add_child(UI.label("Confronto encerrado: "+PlayerText.outcome(b["outcome"]),17,UI.GREEN))
        var next=UI.button("Continuar jornada",true);next.disabled=state.health==0
        next.pressed.connect(func():continue_requested.emit());add_child(next)
    var journal=UI.button("Ver histórico do confronto")
    journal.pressed.connect(func():record_requested.emit());add_child(journal)

