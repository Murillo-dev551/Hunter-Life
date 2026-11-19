extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(120).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func setup(ui,nen: bool=true):
    var s=State.new();s.rng.seed=123;s.start("Menus");s.active_adventure=false;s.current_adventure=""
    if nen:
        s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Reforço"}
        for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
    s.open_event("battle_bandit");s.choose(0);ui.state=s;ui.build_session();return s
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    setup(ui,false);await settle()
    var before: Dictionary=ui.state.serialize().duplicate(true)
    check(ui.adventure_view.category_buttons.size()==4,"Menu principal tem quatro categorias")
    for group in ui.adventure_view.GROUPS:
        ui.adventure_view.category_buttons[group].pressed.emit();await settle()
        check(ui.adventure_view.category==group and not ui.adventure_view.menu.visible,"Abre categoria")
        check(before==ui.state.serialize(),"Navegação não altera RNG, turnos, Saúde, efeitos ou recompensas")
        for action in ui.adventure_view.GROUPS[group]:check(ui.adventure_view.buttons[action].is_visible_in_tree(),"Ações corretas na categoria")
        ui.adventure_view.groups[group].get_child(0).pressed.emit();await settle()
        check(before==ui.state.serialize() and ui.adventure_view.category=="","Voltar não altera estado")
    ui.adventure_view.show_category("nen");await settle()
    for action in ["ten","zetsu","ren","hatsu"]:
        check(ui.adventure_view.buttons[action].disabled and ui.adventure_view.buttons[action].tooltip_text!="","Sem Nen há explicação de indisponibilidade")
        ui.adventure_view.buttons[action].pressed.emit()
        check(before==ui.state.serialize(),"Ação indisponível não consome turno")
    for action in State.Battle.LABELS:
        var s=setup(ui)
        if action=="hatsu":s.hatsu={"id":"reinforce","specialization":"power","learned":true};ui.build_session()
        Store.save(s,"user://test_menu.json")
        var direct=Store.load_state("user://test_menu.json")["state"]
        var group: String=""
        for key in ui.adventure_view.GROUPS:
            if action in ui.adventure_view.GROUPS[key]:group=key
        ui.adventure_view.show_category(group)
        var token: int=s.battle["turn"]
        ui.adventure_view.buttons[action].pressed.emit();direct.Battle.act(direct,action,token);await settle()
        check(ui.state.serialize()==direct.serialize(),"Botão usa a resolução original: "+action)
        check(not ui.state.Battle.active(ui.state) or ui.adventure_view.category=="","Após agir retorna ao menu principal")
        Store.save(ui.state,"user://test_menu.json");var loaded=Store.load_state("user://test_menu.json")
        check(loaded["error"]=="" and loaded["state"].serialize()==ui.state.serialize(),"Confronto persiste após ação")
    for id in State.Hatsu.SPECS:
        for spec in State.Hatsu.SPECS[id]:
            var s=setup(ui);s.nen["category"]=s.Hatsu.category(id);s.hatsu={"id":id,"specialization":spec,"learned":true};ui.build_session()
            ui.adventure_view.show_category("nen");await settle()
            check(ui.adventure_view.buttons["hatsu"].text.contains(s.Hatsu.NAMES[id]) and ui.adventure_view.buttons["hatsu"].text.contains(s.Hatsu.LABELS[spec]),"Somente Hatsu e especialização aprendidos")
            for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(768,1024)]:
                root.size=size;await settle()
                var scroll=ui.pages.get_child(0)
                check(scroll.get_child(0).size.x<=scroll.size.x+1,"Submenu cabe na largura")
                scroll.ensure_control_visible(ui.adventure_view.buttons["hatsu"]);await settle()
                check(ui.adventure_view.buttons["hatsu"].get_global_rect().intersects(scroll.get_global_rect()),"Ação especial acessível")
            Store.save(s,"user://test_menu.json")
            var original=Store.load_state("user://test_menu.json")["state"]
            ui.adventure_view.buttons["hatsu"].pressed.emit();original.Battle.act(original,"hatsu",1);await settle()
            check(ui.state.serialize()==original.serialize(),"Hatsu original executado pelo submenu sem alterar efeito")
            check(not ui.state.Battle.active(ui.state) or ui.adventure_view.category=="","Hatsu retorna ao menu principal")
    setup(ui);ui.state.nen["category"]="Manipulação";ui.state.hatsu={"id":"manipulation","specialization":"objects","learned":true}
    ui.state.battle={};ui.state.open_event("battle_fighter");ui.state.choose(0);ui.build_session();ui.adventure_view.show_category("nen");await settle()
    check(ui.adventure_view.buttons["hatsu"].disabled and ui.adventure_view.buttons["hatsu"].tooltip_text.contains("objeto"),"Alvos de Manipulação continuam limitados")
    for id in State.Affinity.IDS:
        var s=State.new();s.start("Especialista");s.active_adventure=false;s.current_adventure=""
        s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Especialização"}
        for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
        s.open_event("affinity_offer");s.choose(0);s.advance()
        for stage in range(5):
            for i in range(5):
                if s.demo["choices"][i]["affinity_style"]==id:s.choose(i);break
            s.advance()
        s.choose(0);s.open_event("battle_bandit");s.choose(0);ui.state=s;ui.build_session();ui.adventure_view.show_category("nen");await settle()
        check(ui.adventure_view.buttons["hatsu"].text.contains(s.Hatsu.NAMES[id]) and s.nen["category"]=="Especialização","Especialista acessa somente o Hatsu reproduzido")
        before=s.serialize().duplicate(true);ui.adventure_view.show_category();ui.adventure_view.show_category("nen")
        check(before==s.serialize(),"Navegação não altera resultado de afinidade")
        Store.save(s,"user://test_menu.json")
        var reproduced=Store.load_state("user://test_menu.json")["state"]
        ui.adventure_view.buttons["hatsu"].pressed.emit();reproduced.Battle.act(reproduced,"hatsu",1);await settle()
        check(ui.state.serialize()==reproduced.serialize() and ui.state.nen["category"]=="Especialização","Especialista executa Hatsu pelo submenu com as regras existentes")
    setup(ui)
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size;ui.adventure_view.show_category();await settle()
        check(root.get_texture().get_image().save_png("res://tests/captures/10f_combat_%dx%d.png" % [size.x,size.y])==OK,"Captura menu principal")
        for button in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Navegação inferior preservada")
    root.size=Vector2i(390,844);ui.adventure_view.show_category("defend");ui.adventure_view.buttons["defend"].pressed.emit();await settle()
    check(root.get_texture().get_image().save_png("res://tests/captures/10f_combat_result.png")==OK,"Resultado junto ao menu principal")
    ui.adventure_view.show_category("nen");await settle()
    check(root.get_texture().get_image().save_png("res://tests/captures/10f_combat_nen.png")==OK,"Submenu Nen")
    print("MENU COMBATE 10F: %d verificações, %d falhas, 7 capturas" % [checks,failures])
    DirAccess.remove_absolute("user://test_menu.json")
    quit(1 if failures else 0)
