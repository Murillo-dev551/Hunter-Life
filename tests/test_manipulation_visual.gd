extends SceneTree
const State=preload("res://scripts/game_state.gd")
var checks: int=0
var failures: int=0
var captures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func layout(ui) -> void:
    var scroll=ui.pages.get_child(ui.pages.current_tab)
    check(scroll.get_child(0).size.x<=scroll.size.x+1,"Sem transbordamento horizontal")
    for button in ui.navigation:
        check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Navegação cabe na janela")
        check(button.get_global_rect().position.y>=ui.pages.get_global_rect().end.y-1,"Navegação fora da área de texto")
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/10d_"+name+".png")==OK,"Captura gravada")
    captures+=1
func fixture(ui,spec: String) -> void:
    ui.state=State.new();ui.state.start("Aprendiz");ui.state.active_adventure=false;ui.state.current_adventure=""
    ui.state.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Manipulação"}
    for technique in ui.state.nen["techniques"]:ui.state.flags["nen_"+technique]=true
    ui.state.hatsu={"id":"manipulation","specialization":spec,"learned":true}
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    for spec in ["objects","motor"]:
        for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
            root.size=size;fixture(ui,spec);ui.state.open_event("market");ui.build_session();ui.select_tab(1);await settle();layout(ui)
            var scroll=ui.pages.get_child(1)
            for label in ui.character_content.find_children("*","Label",true,false):
                if label.text.begins_with("Agulha de Comando"):scroll.ensure_control_visible(label.get_parent())
            await settle()
            if size.x==390:capture(spec+"_character")
            for enemy in ["bandit","fighter"]:
                fixture(ui,spec);ui.state.open_event("battle_"+enemy);ui.state.choose(0);ui.build_session();await settle();layout(ui)
                ui.adventure_view.show_category("nen");await settle()
                var button: Button=ui.adventure_view.buttons["hatsu"]
                check(button.disabled==(spec=="objects" and enemy=="fighter"),"Disponibilidade visual respeita alvo")
                check(button.text.contains("%") and button.text.contains("Agulha de Comando"),"Nome e probabilidade visíveis")
                scroll=ui.pages.get_child(0);scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
                check(button.get_global_rect().intersects(scroll.get_global_rect()),"Ação acessível por rolagem")
                if spec=="objects" and enemy=="fighter":check(button.tooltip_text.contains("objeto"),"Explicação de falta de alvo")
                if size.x==390:capture(spec+"_"+enemy)
    root.size=Vector2i(390,844);fixture(ui,"objects");ui.state.hatsu=ui.state.Hatsu.fresh();ui.state.open_event("develop_manipulation");ui.build_session();await settle()
    capture("learning");ui.choose(0);await settle()
    check(ui.state.hatsu["learned"],"Sinal aprende especialização")
    layout(ui)
    print("VISUAL MANIPULAÇÃO 10D: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    quit(1 if failures else 0)
