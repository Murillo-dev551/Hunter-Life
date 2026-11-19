extends SceneTree
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(60).timeout.connect(func():quit(1))
    call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func texts(node: Node) -> String:
    var out: String=node.text if node is Label else ""
    for child in node.get_children():out+=texts(child)
    return out
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    ui.start_game("Nara");ui.state.open_event("nen_offer");ui.build_session()
    for i in range(4):ui.choose(0);ui.next_event()
    ui.select_tab(1);await settle()
    var category: String=ui.state.nen["category"]
    check(not texts(ui.character_content).contains(category),"Categoria oculta antes da água")
    ui.select_tab(0);ui.choose(0);ui.next_event();ui.select_tab(1)
    check(texts(ui.character_content).contains(category),"Categoria revelada em Personagem")
    var before: int=ui.state.attributes["agility"]
    ui.state.Progress.award(ui.state,100);ui.build_session();ui.select_tab(1)
    ui.attribute_buttons["agility"].pressed.emit()
    check(ui.state.attributes["agility"]==before+1,"Ponto aplicado")
    ui.state.open_event("bridge");ui.build_session()
    check(ui.adventure_view.choice_buttons[0].text.contains(str(ui.state.Progress.chance(before+1,16))+"%"),"Chance atualizada imediatamente na interface")
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size;ui.select_tab(1);await settle()
        var scroll=ui.pages.get_child(1)
        scroll.scroll_vertical=250;await settle()
        check(scroll.get_child(0).size.x<=scroll.size.x+1,"Seção Nen sem transbordamento")
        for b in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(b.get_global_rect()),"Navegação preservada")
        check(root.get_texture().get_image().save_png("res://tests/captures/nen_%dx%d.png" % [size.x,size.y])==OK,"Captura Nen")
    print("VISUAL NEN: %d verificações, %d falhas, 5 capturas" % [checks,failures])
    quit(1 if failures else 0)
