extends SceneTree
const Slots=preload("res://scripts/save_slots.gd")
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const BASE="user://test_slots_10f/"
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func clean(path: String) -> void:
    var absolute: String=ProjectSettings.globalize_path(path).simplify_path()
    var allowed: String=ProjectSettings.globalize_path(BASE).simplify_path().trim_suffix("/")+"/"
    assert((absolute+"/").begins_with(allowed))
    if not DirAccess.dir_exists_absolute(path):return
    for child in DirAccess.get_directories_at(path):clean(path.path_join(child))
    for file in DirAccess.get_files_at(path):DirAccess.remove_absolute(path.path_join(file))
    DirAccess.remove_absolute(path)
func fixture(name: String):
    var base: String=BASE+name+"/";clean(base)
    return Slots.new(base)
func fresh(name: String,seed_value: int=1):
    var s=State.new();s.rng.seed=seed_value;s.start(name);return s
func specialist(seed_value: int=7):
    var s=fresh("Especialista",seed_value);s.active_adventure=false;s.current_adventure=""
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Especialização"}
    for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
    s.open_event("affinity_offer");return s
func legacy(slots,s) -> void:
    DirAccess.make_dir_recursive_absolute(slots.legacy.get_base_dir());check(Store.save(s,slots.legacy)=="","Cria fixture antiga")
func run() -> void:
    var slots=fixture("basic")
    var states: Array=[]
    for index in range(1,4):
        var s=fresh("Viajante %d" % index,index)
        check(slots.create(index,s)=="","Cria três jornadas independentes")
        var loaded=slots.load_slot(index)
        check(loaded["error"]=="" and loaded["state"].serialize()==s.serialize(),"Carrega integralmente cada slot")
        states.append(s)
    var hashes: Array=[]
    for index in range(1,4):hashes.append(FileAccess.get_sha256(slots.path(index)))
    check(slots.create(1,fresh("Invasor"))!="","Não substitui slot ocupado")
    check(slots.save_slot(1,states[1],slots.token(1))!="","Não salva outra jornada no slot")
    check(slots.save_slot(1,states[0],"token antigo")!="","Sessão antiga não substitui geração atual")
    var s=states[0]
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Emissão"}
    for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
    s.hatsu={"learned":true,"id":"emission","specialization":"precision"}
    s.Items.apply(s,{"items_add":{"knife":1,"vest":1}});s.Items.operate(s,"vest","equip",s.inventory["revision"])
    s.open_event("battle_bandit");s.choose(0);s.Battle.act(s,"defend",1)
    check(slots.save_slot(1,s,slots.token(1))=="","Salva durante confronto")
    var loaded=slots.load_slot(1)
    check(loaded["error"]=="" and loaded["state"].serialize()==s.serialize(),"Preserva Nen, Hatsu, inventário, combate e RNG")
    var clone=loaded["state"];s.Battle.act(s,"hatsu",2);clone.Battle.act(clone,"hatsu",2)
    check(s.serialize()==clone.serialize(),"Continua batalha sem repetir rolagens")
    check(FileAccess.get_sha256(slots.path(2))==hashes[1] and FileAccess.get_sha256(slots.path(3))==hashes[2],"Salvar Slot 1 não altera outros")
    s=states[1];s.active_adventure=false;s.current_adventure="";s.open_event("exam_invite");s.choose(1);s.advance()
    check(slots.save_slot(2,s,slots.token(2))=="" and slots.load_slot(2)["state"].exam==s.exam,"Exame Hunter persiste no slot")
    check(not slots.summary(3)["state"].nen["water_done"],"Resumo usa estado validado sem revelar afinidade oculta")
    slots=fixture("checkpoints");s=specialist();var other=specialist(8)
    check(slots.create(1,s)=="" and slots.create(2,other)=="","Cria jornadas para isolamento")
    var old: Dictionary=s.serialize().duplicate(true)
    s.choose(0);s.advance();s.choose(0)
    check(slots.save_checkpoint(1,s,slots.token(1))=="","Checkpoint pertence ao slot e jornada")
    check(slots.save_checkpoint(2,s,slots.token(2))!="","Slot 2 recusa checkpoint da jornada 1")
    loaded=slots.load_slot(1)
    check(loaded["state"].serialize()==s.serialize(),"Manual antigo retoma decisão registrada")
    check(slots.load_slot(2)["state"].affinity["phase"]=="unstarted","Slot 2 não recebe decisões do Slot 1")
    check(slots.load_slot(2)["state"].serialize()==other.serialize(),"Carregar outro slot não o modifica")
    var previous_token: String=slots.token(1)
    check(slots.delete_slot(1,previous_token)!="" and slots.occupied(1),"Exclusão exige confirmação")
    check(slots.delete_slot(1,previous_token,true)=="" and not slots.occupied(1),"Exclusão confirmada limpa slot")
    check(DirAccess.get_files_at(slots.checkpoints(1)).is_empty(),"Remove checkpoints da jornada excluída")
    check(slots.create(1,specialist())=="","Reutiliza slot com mesma semente e nome sem herdar avaliação")
    check(slots.token(1)!=previous_token and slots.load_slot(1)["state"].affinity["phase"]=="unstarted","Nova geração não herda checkpoint")
    check(slots.delete_slot(1,previous_token,true)!="" and slots.occupied(1),"Confirmação antiga não exclui nova jornada")
    slots=fixture("migration");s=specialist(20);legacy(slots,s)
    var original_hash: String=FileAccess.get_sha256(slots.legacy)
    s.choose(0);s.advance();s.choose(0);Store.save_affinity(s,slots.legacy_checkpoints)
    check(slots.migrate_legacy().contains("migrado"),"Migra arquivo manual para Slot 1")
    check(FileAccess.get_sha256(slots.legacy)==original_hash,"Original permanece idêntico")
    check(slots.load_slot(1)["state"].serialize()==s.serialize(),"Migração preserva checkpoint antigo mais adiantado")
    check(slots.legacy_candidates().is_empty(),"Registro associado não é oferecido a outro slot")
    var migrated_hash: String=FileAccess.get_sha256(slots.path(1))
    check(slots.migrate_legacy()=="" and FileAccess.get_sha256(slots.path(1))==migrated_hash,"Não migra novamente")
    check(slots.delete_slot(1,slots.token(1),true)=="","Exclui jornada migrada")
    check(not FileAccess.file_exists(slots.legacy_checkpoints+Store.affinity_key(s)+".json"),"Exclusão remove checkpoint antigo associado")
    check(slots.migrate_legacy()=="" and not slots.occupied(1),"Backup original não ressuscita jornada excluída")
    slots=fixture("occupied");s=fresh("Antigo");legacy(slots,s);slots.create(1,fresh("Atual",2))
    original_hash=FileAccess.get_sha256(slots.legacy);migrated_hash=FileAccess.get_sha256(slots.path(1))
    check(slots.migrate_legacy().contains("ocupado") and FileAccess.get_sha256(slots.path(1))==migrated_hash and FileAccess.get_sha256(slots.legacy)==original_hash,"Migração não substitui Slot 1 ocupado")
    slots=fixture("invalid");DirAccess.make_dir_recursive_absolute(slots.legacy.get_base_dir())
    var f=FileAccess.open(slots.legacy,FileAccess.WRITE);f.store_string("{ inválido");f.close()
    check(slots.migrate_legacy().contains("preservado") and not slots.occupied(1),"Arquivo antigo inválido não trava nem é apagado")
    slots=fixture("interrupted");s=fresh("Interrompido",30);legacy(slots,s)
    var receipt: Dictionary={"hash":FileAccess.get_sha256(slots.legacy),"journey":Store.affinity_key(s),"token":"migration-token","status":"pending"}
    slots.write_json(slots.root+"legacy_migration.json",receipt)
    slots.write_json(slots.directory(1)+"owner.json",{"token":"migration-token","journey":Store.affinity_key(s),"status":"creating","legacy_owned":false})
    check(slots.migrate_legacy().contains("migrado") and slots.load_slot(1)["state"].serialize()==s.serialize(),"Retoma migração interrompida antes de gravar save")
    slots=fixture("interrupted_after_save");s=fresh("Já gravado",31);legacy(slots,s)
    receipt={"hash":FileAccess.get_sha256(slots.legacy),"journey":Store.affinity_key(s),"token":"recovered-token","status":"pending"}
    slots.write_json(slots.root+"legacy_migration.json",receipt);DirAccess.make_dir_recursive_absolute(slots.directory(1));Store.save(s,slots.path(1))
    check(slots.migrate_legacy().contains("migrado") and slots.token(1)=="recovered-token","Recupera migração com save pronto e identificação pendente")
    slots=fixture("broken_target");s=fresh("Fonte intacta",32);legacy(slots,s)
    slots.write_json(slots.root+"legacy_migration.json",{"hash":FileAccess.get_sha256(slots.legacy),"journey":Store.affinity_key(s),"token":"pending","status":"pending"})
    slots.write_json(slots.directory(1)+"owner.json",{"token":"pending","journey":Store.affinity_key(s),"status":"creating","legacy_owned":false})
    f=FileAccess.open(slots.path(1),FileAccess.WRITE);f.store_string("inválido");f.close()
    original_hash=FileAccess.get_sha256(slots.legacy);migrated_hash=FileAccess.get_sha256(slots.path(1))
    check(not slots.migrate_legacy().contains("migrado") and FileAccess.get_sha256(slots.legacy)==original_hash and FileAccess.get_sha256(slots.path(1))==migrated_hash,"Falha preserva fonte e destino para recuperação")
    slots=fixture("orphan_checkpoint");s=specialist(40);s.choose(0);s.advance();s.choose(0);Store.save_affinity(s,slots.legacy_checkpoints)
    check(slots.legacy_candidates().size()==1,"Reconhece checkpoint antigo sem arquivo manual")
    check(slots.import_checkpoint(3,Store.affinity_key(s))=="" and slots.load_slot(3)["state"].serialize()==s.serialize(),"Recupera checkpoint antigo em slot vazio")
    check(slots.import_checkpoint(2,Store.affinity_key(s))!="","Não associa mesma avaliação a outro slot")
    check(slots.delete_slot(3,slots.token(3),true)=="" and slots.legacy_candidates().is_empty(),"Excluir remove registro recuperado sem deixá-lo reaparecer")
    slots=fixture("same_seed_name");s=specialist(55);other=specialist(55)
    check(slots.create(1,s)=="" and slots.create(2,other)=="","Gerações distintas aceitam mesmo nome e semente em fixtures")
    other.choose(0);other.advance();other.choose(0)
    check(slots.save_checkpoint(1,other,slots.token(1))!="","Geração impede checkpoint cruzado mesmo com mesma identificação antiga")
    check(slots.save_slot(1,other,slots.token(1))!="","Geração impede gravação cruzada de jornadas equivalentes")
    slots=fixture("historical_v8");s=fresh("Histórico v8",88)
    var previous: Dictionary=s.serialize().duplicate(true);previous["version"]=8;previous.erase("exam");previous.erase("affinity")
    DirAccess.make_dir_recursive_absolute(slots.legacy.get_base_dir());f=FileAccess.open(slots.legacy,FileAccess.WRITE);f.store_string(JSON.stringify(previous));f.close()
    check(slots.migrate_legacy().contains("migrado") and slots.load_slot(1)["state"].serialize()==s.serialize(),"Migração de arquivo histórico v8 preserva dados e inicializa campos compatíveis")
    print("SLOTS 10F: %d verificações, %d falhas" % [checks,failures])
    clean(BASE)
    quit(1 if failures else 0)
