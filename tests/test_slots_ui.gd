extends SceneTree
const Slots=preload("res://scripts/save_slots.gd")
const BASE="user://test_slots_ui_10f/"
var checks: int=0
var failures: int=0
func _initialize() -> void:
    create_timer(90).timeout.connect(func():quit(1));call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func clean(path: String) -> void:
    assert((ProjectSettings.globalize_path(path).simplify_path()+"/").begins_with(ProjectSettings.globalize_path(BASE).simplify_path().trim_suffix("/")+"/"))
    if not DirAccess.dir_exists_absolute(path):return
    for child in DirAccess.get_directories_at(path):clean(path.path_join(child))
    for file in DirAccess.get_files_at(path):DirAccess.remove_absolute(path.path_join(file))
    DirAccess.remove_absolute(path)
func settle() -> void:
    for i in range(5):await process_frame
    await RenderingServer.frame_post_draw
func layout(ui) -> void:
    var scroll=ui.pages.get_child(0)
    check(scroll.get_child(0).size.x<=scroll.size.x+1,"Slots sem transbordamento horizontal")
    for button in ui.navigation:check(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(button.get_global_rect()),"Navegação dentro da janela")
func run() -> void:
    clean(BASE)
    change_scene_to_file("res://main.tscn");await settle()
    var ui=current_scene;ui.slots=Slots.new(BASE);ui.show_slots();await settle()
    for index in range(1,4):
        check(ui.slot_buttons[index].has("create"),"Três slots vazios apresentados")
        ui.slot_buttons[index]["create"].pressed.emit();await settle()
        ui.creation_view.name_input.text="Jornada %d" % index
        ui.creation_view.start_button.pressed.emit();await settle()
        check(ui.active_slot==index and ui.slots.occupied(index),"Sinal cria na posição escolhida")
        ui.show_slots();await settle()
    var hashes: Array=[]
    for index in range(1,4):
        hashes.append(FileAccess.get_sha256(ui.slots.path(index)))
        ui.slot_buttons[index]["load"].pressed.emit();await settle()
        check(ui.state.character_name=="Jornada %d" % index and ui.active_slot==index,"Sinal carrega jornada correta")
        ui.show_slots();await settle()
    ui.begin_new_slot(1);await settle()
    check(FileAccess.get_sha256(ui.slots.path(1))==hashes[0] and ui.creation_view==null,"Slot ocupado não abre criação por engano")
    root.size=Vector2i(320,480);ui.slot_buttons[2]["delete"].pressed.emit();await settle()
    check(ui.delete_dialog.visible and ui.slots.occupied(2),"Excluir abre confirmação sem remover arquivo")
    check(ui.delete_dialog.size.x<=root.size.x,"Confirmação cabe na janela compacta")
    ui.delete_dialog.get_cancel_button().pressed.emit();await settle()
    check(ui.slots.occupied(2) and not ui.delete_dialog.visible,"Cancelar preserva jornada")
    ui.request_slot_deletion(2);await settle();ui.delete_dialog.get_ok_button().pressed.emit();await settle()
    check(not ui.slots.occupied(2) and ui.slot_buttons[2].has("create"),"Confirmar libera slot")
    check(FileAccess.get_sha256(ui.slots.path(1))==hashes[0] and FileAccess.get_sha256(ui.slots.path(3))==hashes[2],"Excluir não altera outros slots")
    var retained: Dictionary=ui.state.serialize().duplicate(true)
    var retained_slot: int=ui.active_slot
    ui.begin_new_slot(2);ui.show_slots();await settle()
    check(ui.active_slot==retained_slot and ui.state.serialize()==retained,"Cancelar criação mantém sessão atual em memória")
    ui.begin_new_slot(2);ui.creation_view.name_input.text="Nova jornada 2";ui.creation_view.start_button.pressed.emit();await settle()
    check(ui.active_slot==2 and ui.state.character_name=="Nova jornada 2","Reutilização segura pela interface")
    ui.show_slots();ui.load_slot(1);await settle()
    ui.state.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Especialização"}
    for technique in ui.state.nen["techniques"]:ui.state.flags["nen_"+technique]=true
    ui.save_current();ui.state.open_event("affinity_offer");ui.build_session();ui.choose(0);ui.next_event();ui.choose(0);await settle()
    var checkpoint: Dictionary=ui.state.serialize().duplicate(true)
    ui.show_slots();ui.load_slot(3);await settle()
    check(ui.state.affinity["phase"]=="unstarted","Outra jornada não recebe avaliação")
    ui.show_slots();ui.load_slot(1);await settle()
    check(ui.state.serialize()==checkpoint,"Carregar slot retoma avaliação sem repetir decisão")
    ui.next_event()
    for stage in range(4):ui.choose(0);ui.next_event()
    ui.choose(0);await settle()
    var learned: Dictionary=ui.state.serialize().duplicate(true)
    ui.show_slots();ui.load_slot(1);await settle()
    check(ui.state.serialize()==learned and ui.state.hatsu["learned"],"Slot retoma afinidade e especialização definitivas")
    ui.show_slots();await settle()
    for size in [Vector2i(320,480),Vector2i(390,844),Vector2i(480,860),Vector2i(768,1024),Vector2i(1100,720)]:
        root.size=size;await settle();layout(ui)
        var scroll=ui.pages.get_child(0)
        scroll.scroll_vertical=int(scroll.get_v_scroll_bar().max_value);await settle()
        check(ui.slot_buttons[3]["delete"].get_global_rect().intersects(scroll.get_global_rect()),"Terceiro slot acessível por rolagem")
        scroll.scroll_vertical=0;await settle()
        check(root.get_texture().get_image().save_png("res://tests/captures/10f_slots_%dx%d.png" % [size.x,size.y])==OK,"Captura dos slots")
    print("UI SLOTS 10F: %d verificações, %d falhas, 5 capturas" % [checks,failures])
    clean(BASE)
    quit(1 if failures else 0)
