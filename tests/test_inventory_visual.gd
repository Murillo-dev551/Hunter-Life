extends SceneTree
const Driver=preload("res://tests/battle_driver.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene;ui.start_game("Mochila")
    ui.state.open_event("supply_stall");ui.build_session();ui.choose(0)
    check(ui.inventory_view.buttons.has("bandage"),"Compra atualiza Inventário sem avançar evento")
    ui.state.inventory=ui.state.Items.fresh()
    ui.state.Items.apply(ui.state,{"items_add":{"bandage":2,"medicine":1,"knife":1,"vest":1,"rope":1,"lantern":1,"map":1,"souvenir":1}})
    ui.state.health=4;ui.build_session();ui.select_tab(2)
    var old_token: int=ui.state.inventory["revision"]
    ui.inventory_view.buttons["bandage"].pressed.emit();await settle()
    check(ui.state.health==7 and ui.state.Items.quantity(ui.state,"bandage")==1,"Sinal usa uma unidade e atualiza Saúde")
    check(not ui.state.Items.operate(ui.state,"bandage","use",old_token),"Duplo clique antigo bloqueado")
    ui.inventory_view.buttons["knife"].pressed.emit();await settle()
    check(ui.state.inventory["equipment"]["weapon"]=="knife","Sinal equipa arma")
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size;await settle()
        var scroll=ui.pages.get_child(2)
        scroll.scroll_vertical=0;await settle()
        check(scroll.get_child(0).size.x<=scroll.size.x+1,"Inventário sem transbordamento")
        for b in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(b.get_global_rect()),"Navegação cabe")
        check(root.get_texture().get_image().save_png("res://tests/captures/inventory_%dx%d.png" % [size.x,size.y])==OK,"Captura inventário")
    ui.state.open_event("battle_bandit");ui.build_session();ui.choose(0);ui.select_tab(2)
    check(ui.inventory_view.buttons.values().all(func(b):return b.disabled),"Todos os usos e trocas bloqueados em combate")
    print("VISUAL INVENTÁRIO: %d verificações, %d falhas, 5 capturas" % [checks,failures])
    quit(1 if failures else 0)

