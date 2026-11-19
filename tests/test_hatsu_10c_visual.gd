extends SceneTree
const State=preload("res://scripts/game_state.gd")
var checks: int=0
var failures: int=0
var captures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(message)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func layout(ui) -> void:
    var scroll=ui.pages.get_child(ui.pages.current_tab)
    check(scroll.get_child(0).size.x<=scroll.size.x+1,"Conteúdo cabe horizontalmente")
    for button in ui.navigation:
        check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Navegação visível")
        check(button.get_global_rect().position.y>=ui.pages.get_global_rect().end.y-1,"Texto separado da navegação")
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/10c_"+name+".png")==OK,"Captura gravada")
    captures+=1
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    for id in ["transmutation","conjuration"]:
        for index in range(2):
            ui.state=State.new();ui.state.start("Aprendiz");ui.state.active_adventure=false;ui.state.current_adventure=""
            ui.state.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":ui.state.Hatsu.category(id)}
            for technique in ui.state.nen["techniques"]:ui.state.flags["nen_"+technique]=true
            ui.state.open_event("develop_"+id);ui.build_session();await settle()
            ui.choose(index);check(ui.state.hatsu["learned"],"Escolha aprende o Hatsu")
            for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
                root.size=size;ui.select_tab(1);await settle();layout(ui)
                var scroll=ui.pages.get_child(1)
                for label in ui.character_content.find_children("*","Label",true,false):
                    if label.text.begins_with(ui.state.Hatsu.NAMES[id]):scroll.ensure_control_visible(label.get_parent())
                await settle()
                if size.x==390:capture(id+"_%d_character" % index)
                ui.state.battle={};ui.state.open_event("battle_fighter");ui.state.choose(0);ui.build_session();await settle();layout(ui)
                ui.adventure_view.show_category("nen");await settle()
                var button: Button=ui.adventure_view.buttons["hatsu"]
                check(button.text.contains(ui.state.Hatsu.NAMES[id]),"Nome correto no botão")
                check(button.text.contains("%"),"Probabilidade real visível")
                scroll=ui.pages.get_child(0);scroll.ensure_control_visible(button);await settle()
                check(button.get_global_rect().intersects(scroll.get_global_rect()),"Hatsu acessível por rolagem")
                if size.x==390:capture(id+"_%d_battle" % index)
                ui.battle_action("hatsu",1);await settle();layout(ui)
                if size.x==390:capture(id+"_%d_result" % index)
                ui.state.battle={}
    print("VISUAL HATSUS 10C: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    quit(1 if failures else 0)
