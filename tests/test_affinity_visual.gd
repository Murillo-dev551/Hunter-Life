extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const DIRECTORY="user://test_affinity_ui/"
var checks: int=0
var failures: int=0
var captures: int=0
var files: Array[String]=[]
func _initialize() -> void:
    create_timer(120).timeout.connect(func():push_error("Avaliação visual excedeu o tempo");quit(1));call_deferred("run")
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
        check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Navegação visível")
        check(button.get_global_rect().position.y>=ui.pages.get_global_rect().end.y-1,"Texto separado da navegação")
func capture(name: String) -> void:
    check(root.get_texture().get_image().save_png("res://tests/captures/10e_"+name+".png")==OK,"Captura gravada")
    captures+=1
func run() -> void:
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene
    ui.affinity_checkpoint_dir=DIRECTORY
    for id in State.Affinity.IDS:
        ui.state=State.new();ui.state.rng.seed=100+State.Affinity.IDS.find(id);ui.state.start("Avaliação visual")
        ui.state.active_adventure=false;ui.state.current_adventure=""
        ui.state.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Especialização"}
        for technique in ui.state.nen["techniques"]:ui.state.flags["nen_"+technique]=true
        ui.state.open_event("affinity_offer");ui.build_session();ui.choose(0)
        files.append(DIRECTORY+Store.affinity_key(ui.state)+".json")
        ui.next_event()
        for stage in range(5):
            root.size=Vector2i(320,480);await settle();layout(ui)
            check(ui.state.current_id=="affinity_trial_%d" % (stage+1),"Cena correta")
            var index: int=-1
            for i in range(5):
                if ui.state.demo["choices"][i]["affinity_style"]==id:index=i
            if id=="reinforce" and stage==0:capture("trial_compact")
            ui.choose(index);await settle()
            check(ui.state.affinity["decisions"].size()==stage+1,"Decisão registrada")
            if stage==4:
                var early_reveal: bool=false
                for label in ui.character_content.find_children("*","Label",true,false):
                    if label.text.begins_with("Afinidade desenvolvida:"):early_reveal=true
                check(not early_reveal,"A ficha não antecipa a revelação narrativa de Mira")
            if stage==1:
                var saved: Dictionary=ui.state.serialize().duplicate(true)
                ui.show_creation();await settle()
                var resume: Button
                for button in ui.pages.find_children("*","Button",true,false):
                    if button.text=="Retomar registro de Mira":resume=button
                check(resume!=null,"Retomada disponível na criação")
                if resume:resume.pressed.emit();await settle()
                check(ui.state.serialize()==saved,"Retoma checkpoint sem rerrolar")
            ui.next_event();await settle()
            check(ui.pages.get_child(0).scroll_vertical==0,"Continuação volta ao topo")
        check(ui.state.affinity["result"]==id,"Revelação coerente")
        for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
            root.size=size;await settle();layout(ui)
            var scroll=ui.pages.get_child(0)
            scroll.scroll_vertical=0;await settle()
            if size.x==390:capture(id+"_revelation")
            scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
            check(ui.adventure_view.choice_buttons.back().get_global_rect().intersects(scroll.get_global_rect()),"Última especialização alcançável")
        ui.choose(0);await settle()
        check(ui.state.hatsu["learned"] and ui.state.nen["category"]=="Especialização","Aprende sem mudar categoria")
        check(Store.latest_affinity(DIRECTORY)["state"].affinity["phase"]=="learned","Escolha interna registrada automaticamente")
        ui.select_tab(1);root.size=Vector2i(390,844);await settle();layout(ui)
        var scroll=ui.pages.get_child(1)
        var category_seen: bool=false
        var affinity_seen: bool=false
        for label in ui.character_content.find_children("*","Label",true,false):
            if label.text=="Categoria: Especialização":category_seen=true
            if label.text.begins_with("Afinidade desenvolvida:"):affinity_seen=true;scroll.ensure_control_visible(label.get_parent())
        await settle()
        check(category_seen and affinity_seen,"Personagem distingue categoria e afinidade")
        capture(id+"_character")
    print("VISUAL AFINIDADE 10E: %d verificações, %d falhas, %d capturas" % [checks,failures,captures])
    for path in files:DirAccess.remove_absolute(path)
    DirAccess.remove_absolute(DIRECTORY+"latest")
    quit(1 if failures else 0)
