extends VBoxContainer
signal continue_requested
signal action_requested(id: String, token: int)
signal record_requested
signal menu_changed
const UI=preload("res://scripts/ui/styles.gd")
const PlayerText=preload("res://scripts/ui/player_text.gd")
var buttons: Dictionary={}
const GROUPS={"attack":["attack","quick"],"defend":["defend","dodge"],"nen":["ten","zetsu","ren","hatsu"],"other":["flee","yield"]}
const GROUP_NAMES={"attack":"Atacar","defend":"Defender","nen":"Nen / Hatsu","other":"Outras ações"}
var category_buttons: Dictionary={}
var groups: Dictionary={}
var menu: GridContainer
var category: String=""
var result_panel: Control
var status_panel: Control
func show_category(id: String="") -> void:
    if id!="" and not GROUPS.has(id):return
    category=id
    UI.sound("back" if id=="" else "tab")
    menu.visible=id==""
    for key in groups:groups[key].visible=key==id
    UI.Motion.enter(menu if id=="" else groups[id])
    menu_changed.emit()
func build(state) -> void:
    var b: Dictionary=state.battle
    var card=UI.card(self)
    result_panel=card.get_parent()
    status_panel=card.get_parent()
    UI.section(card,"CONFRONTO · TURNO %d" % b["turn"],"attack")
    card.add_child(UI.title(state.Battle.ENEMIES[b["enemy"]]["name"],28))
    card.add_child(UI.label(state.Battle.ENEMIES[b["enemy"]]["description"],14))
    if state.hatsu["id"]=="manipulation" and state.hatsu["specialization"]=="objects" and state.Battle.object_target(state)!="":card.add_child(UI.label("Uma fivela solta pende do cinturão, ao alcance quando ele se aproxima.",14,UI.MUTED))
    card.add_child(UI.label("Sua Saúde: %d/10 · Adversário: %d/%d\nTurno %d" % [state.health,b["hp"],state.Battle.ENEMIES[b["enemy"]]["hp"],b["turn"]],16))
    if not b["log"].is_empty():
        var last=UI.card(self);result_panel=last.get_parent();last.add_child(UI.label("\n".join(b["log"].slice(-2)) if b["outcome"]!="" else b["log"][-1],15,UI.ALERT if state.health<=3 else UI.INK))
    if state.Battle.active(state):
        add_child(UI.label("Intenção: "+state.Battle.INTENTS[b["intent"]],16,UI.GREEN))
        if b["opening"]:add_child(UI.label("Você tem uma abertura para contra-atacar.",14))
        add_child(HSeparator.new())
        menu=GridContainer.new();menu.columns=2;menu.add_theme_constant_override("h_separation",8);menu.add_theme_constant_override("v_separation",8);add_child(menu)
        for group in GROUPS:
            var category_button=UI.button(GROUP_NAMES[group],group=="attack")
            UI.button_icon(category_button,group)
            category_button.add_theme_font_size_override("font_size",14)
            category_button.pressed.connect(func():show_category(group))
            menu.add_child(category_button);category_buttons[group]=category_button
            var content=VBoxContainer.new();content.add_theme_constant_override("separation",8);content.hide();add_child(content);groups[group]=content
            var back=UI.button("Voltar ao menu principal")
            back.add_theme_font_size_override("font_size",14)
            back.pressed.connect(func():show_category());content.add_child(back)
            var heading=HBoxContainer.new();heading.add_child(UI.icon(group));heading.add_child(UI.label(GROUP_NAMES[group],17,UI.GREEN));content.add_child(heading)
        for id in state.Battle.LABELS:
            var group: String=""
            for key in GROUPS:
                if id in GROUPS[key]:group=key;break
            var text: String=state.Battle.LABELS[id]
            if id=="hatsu" and state.hatsu["learned"]:text=state.Hatsu.NAMES[state.hatsu["id"]]+"\n"+state.Hatsu.LABELS[state.hatsu["specialization"]]
            var test: Dictionary=state.Battle.test(state,id) if id!="hatsu" or state.hatsu["learned"] else {}
            if not test.is_empty():text+="\n%s · Dif. %d · %d%%" % [state.ATTRIBUTE_NAMES[test["attribute"]],test["difficulty"],state.Progress.chance(state.attributes[test["attribute"]],test["difficulty"])]
            var button=UI.button(text,id=="attack")
            button.add_theme_font_size_override("font_size",14)
            button.custom_minimum_size.y=76 if not test.is_empty() else 52
            button.custom_minimum_size.y=maxf(button.custom_minimum_size.y,28+text.split("\n").size()*24)
            button.disabled=state.Battle.reason(state,id)!="";button.tooltip_text=state.Battle.reason(state,id)
            var token: int=b["turn"]
            button.pressed.connect(func():action_requested.emit(id,token))
            groups[group].add_child(button);buttons[id]=button
            if button.disabled:groups[group].add_child(UI.label(state.Battle.reason(state,id),14,UI.MUTED))
    else:
        add_child(UI.label("Confronto encerrado: "+PlayerText.outcome(b["outcome"]),17,UI.GREEN))
        var next=UI.button("Continuar jornada",true);next.disabled=state.health==0
        next.pressed.connect(func():continue_requested.emit());add_child(next)
    var journal=UI.button("Ver histórico do confronto")
    journal.pressed.connect(func():record_requested.emit());add_child(journal)

