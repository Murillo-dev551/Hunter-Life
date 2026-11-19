extends SceneTree
var checks: int = 0
var failures: int = 0
var captures: int = 0
func _initialize() -> void:
    create_timer(90).timeout.connect(func(): push_error("Tempo excedido no teste visual"); quit(1))
    call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks += 1
    if not ok: failures += 1; push_error(text)
func settle() -> void:
    for i in range(5): await process_frame
    await RenderingServer.frame_post_draw
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/"+name+".png")==OK,"Captura gravada")
    captures += 1
func layout() -> void:
    var ui = current_scene
    var bounds = Rect2(Vector2.ZERO,Vector2(root.size))
    for b in ui.navigation:
        check(bounds.encloses(b.get_global_rect()),"Navegação cabe na janela")
        check(b.get_global_rect().position.y>=ui.pages.get_global_rect().end.y-1,"Conteúdo não sobrepõe navegação")
    var scroll = ui.pages.get_child(ui.pages.current_tab)
    check(scroll.get_child(0).size.x<=scroll.size.x+1,"Sem transbordamento horizontal")
    check(bounds.encloses(ui.journal_button.get_global_rect()),"Cabeçalho cabe na janela")
func run() -> void:
    change_scene_to_file("res://main.tscn")
    await settle()
    var ui = current_scene
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size
        ui.show_creation()
        await settle()
        layout()
        capture("criacao_%dx%d" % [size.x,size.y])
        var scroll = ui.pages.get_child(0)
        scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value)
        await settle()
        check(ui.creation_view.start_button.get_global_rect().intersects(scroll.get_global_rect()),"Iniciar partida acessível por rolagem")
        capture("criacao_atributos_%dx%d" % [size.x,size.y])
        ui.creation_view.name_input.text="Nara"
        ui.creation_view.start_button.pressed.emit()
        ui.state.open_event("market");ui.build_session()
        await settle()
        for i in range(4):
            ui.navigation[i].pressed.emit()
            await settle()
            layout()
            capture("aba_%d_%dx%d" % [i,size.x,size.y])
        ui.navigation[0].pressed.emit()
        ui.adventure_view.choice_buttons[0].pressed.emit()
        await settle()
        layout()
        check(ui.adventure_view.consequence.is_visible_in_tree(),"Consequência visível")
        capture("resultado_%dx%d" % [size.x,size.y])
    for i in range(3):
        ui.show_creation()
        ui.start_game("Teste de escolha")
        ui.state.open_event("market");ui.build_session()
        ui.adventure_view.choice_buttons[i].pressed.emit()
        await settle()
        check(ui.adventure_view.result_text.text==ui.state.result,"Resultado correto de cada escolha")
    print("VISUAL HUNTER LIFE: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    quit(1 if failures else 0)



