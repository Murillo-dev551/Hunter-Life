extends RefCounted
const Storage=preload("res://scripts/storage.gd")
var root: String="user://saves/"
var legacy: String=Storage.PATH
var legacy_checkpoints: String=Storage.AFFINITY_DIR
func _init(base: String="") -> void:
    var configured: String=base if base!="" else OS.get_environment("HUNTER_LIFE_DATA_ROOT")
    if configured!="":
        root=configured.trim_suffix("/")+"/saves/"
        legacy=configured.trim_suffix("/")+"/hunter_life.json"
        legacy_checkpoints=configured.trim_suffix("/")+"/affinity_checkpoints/"
func directory(slot: int) -> String:return root+"slot_%d/" % slot
func path(slot: int) -> String:return directory(slot)+"save.json"
func checkpoints(slot: int) -> String:return directory(slot)+"checkpoints/"
func valid_slot(slot: int) -> bool:return slot>=1 and slot<=3
func occupied(slot: int) -> bool:
    return valid_slot(slot) and (FileAccess.file_exists(path(slot)) or FileAccess.file_exists(directory(slot)+"owner.json") or DirAccess.dir_exists_absolute(checkpoints(slot)) and not DirAccess.get_files_at(checkpoints(slot)).is_empty())
func summary(slot: int) -> Dictionary:
    if not occupied(slot):return {"empty":true,"error":""}
    var data: Dictionary=owner(slot)
    if FileAccess.file_exists(directory(slot)+"owner.json") and (data.is_empty() or data.get("status") not in ["creating","ready","deleting"] or not data.get("token") is String or data["token"]==""):return {"empty":false,"error":"Registro do slot inválido; arquivos preservados."}
    if data.get("status")=="deleting":return {"empty":false,"error":"Exclusão interrompida. Confirme novamente para concluir."}
    var loaded: Dictionary=Storage.load_state(path(slot),false)
    if loaded["error"]=="" and not data.is_empty() and data.get("journey")!=Storage.affinity_key(loaded["state"]):loaded={"error":"Identificação do slot incompatível."}
    if loaded["error"]=="":loaded=Storage.restore_affinity(loaded["state"],checkpoints(slot))
    loaded["empty"]=false
    return loaded
func read_json(file_path: String) -> Dictionary:
    if not FileAccess.file_exists(file_path):return {}
    var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(file_path))
    return value if value is Dictionary else {}
func write_json(file_path: String,value: Dictionary) -> String:
    if DirAccess.make_dir_recursive_absolute(file_path.get_base_dir())!=OK:return "Não foi possível preparar a pasta de salvamento."
    var f=FileAccess.open(file_path+".tmp",FileAccess.WRITE)
    if not f:return "Não foi possível gravar o registro."
    f.store_string(JSON.stringify(value));f.flush();var code: Error=f.get_error();f.close()
    if code!=OK or DirAccess.rename_absolute(file_path+".tmp",file_path)!=OK:return "Falha ao concluir a gravação do registro."
    return ""
func owner(slot: int) -> Dictionary:return read_json(directory(slot)+"owner.json")
func token(slot: int) -> String:
    var data: Dictionary=owner(slot)
    if data.get("token") is String:return data["token"]
    return "invalid:"+(FileAccess.get_sha256(path(slot)) if FileAccess.file_exists(path(slot)) else "")+(FileAccess.get_sha256(directory(slot)+"owner.json") if FileAccess.file_exists(directory(slot)+"owner.json") else "")
func create(slot: int,state,owner_token: String="") -> String:
    if not valid_slot(slot):return "Slot inválido."
    if state.character_name.is_empty():return "Crie um personagem primeiro."
    if occupied(slot):return "Este slot já está ocupado."
    if DirAccess.dir_exists_absolute(checkpoints(slot)) and not DirAccess.get_files_at(checkpoints(slot)).is_empty():return "Há registros de uma exclusão incompleta neste slot."
    var data: Dictionary={"token":owner_token if owner_token!="" else Crypto.new().generate_random_bytes(16).hex_encode(),"journey":Storage.affinity_key(state),"status":"creating","legacy_owned":false}
    var error: String=write_json(directory(slot)+"owner.json",data)
    if error!="":return error
    error=Storage.save(state,path(slot))
    if error!="":return error
    var verified: Dictionary=Storage.load_state(path(slot),false)
    if verified["error"]!="":return verified["error"]
    data["status"]="ready"
    error=write_json(directory(slot)+"owner.json",data)
    if error=="":state.set_meta("save_slot_generation",data["token"])
    return error
func load_slot(slot: int) -> Dictionary:
    if not valid_slot(slot):return {"error":"Slot inválido."}
    if not occupied(slot):return {"error":"Este slot está vazio."}
    var data: Dictionary=owner(slot)
    if data.get("status")=="deleting":return {"error":"A exclusão deste slot foi interrompida. Confirme a exclusão novamente."}
    var loaded: Dictionary=Storage.load_state(path(slot),false)
    if loaded["error"]!="":return loaded
    var state=loaded["state"]
    if data.is_empty():
        if FileAccess.file_exists(directory(slot)+"owner.json"):return {"error":"Identificação do slot inválida; arquivos preservados."}
        var receipt: Dictionary=read_json(root+"legacy_migration.json")
        data={"token":receipt.get("token",Crypto.new().generate_random_bytes(16).hex_encode()) if slot==1 and receipt.get("journey")==Storage.affinity_key(state) else Crypto.new().generate_random_bytes(16).hex_encode(),"journey":Storage.affinity_key(state),"status":"ready","legacy_owned":false}
    if data.get("journey")!=Storage.affinity_key(state) or not data.get("token") is String or data["token"]=="":return {"error":"A jornada não corresponde à identificação deste slot."}
    if data.get("status") not in ["creating","ready"]:return {"error":"Registro do slot inválido."}
    if data["status"]=="creating" or not FileAccess.file_exists(directory(slot)+"owner.json"):
        data["status"]="ready"
        var error: String=write_json(directory(slot)+"owner.json",data)
        if error!="":return {"error":error}
    var restored: Dictionary=Storage.restore_affinity(state,checkpoints(slot))
    if restored["error"]!="":return restored
    restored["state"].set_meta("save_slot_generation",data["token"])
    restored["token"]=data["token"]
    return restored
func verify(slot: int,state,owner_token: String) -> String:
    if not valid_slot(slot) or not occupied(slot):return "O slot não está disponível."
    var data: Dictionary=owner(slot)
    if data.get("status")!="ready" or data.get("token")!=owner_token or state.get_meta("save_slot_generation","")!=owner_token or data.get("journey")!=Storage.affinity_key(state):return "Esta sessão não pertence à jornada atual do slot."
    return ""
func save_slot(slot: int,state,owner_token: String) -> String:
    var error: String=verify(slot,state,owner_token)
    return error if error!="" else Storage.save(state,path(slot))
func save_checkpoint(slot: int,state,owner_token: String) -> String:
    var error: String=verify(slot,state,owner_token)
    return error if error!="" else Storage.save_affinity(state,checkpoints(slot))
func bound(key: String) -> bool:
    for slot in range(1,4):
        if occupied(slot) and owner(slot).get("journey")==key:return true
    return false
func legacy_candidates() -> Array:
    var result: Array=[]
    if not DirAccess.dir_exists_absolute(legacy_checkpoints):return result
    for file in DirAccess.get_files_at(legacy_checkpoints):
        if not file.ends_with(".json"):continue
        var loaded: Dictionary=Storage.load_state(legacy_checkpoints+file,false)
        if loaded["error"]!="":continue
        var key: String=Storage.affinity_key(loaded["state"])
        if file==key+".json" and loaded["state"].affinity["phase"]!="unstarted" and not bound(key):result.append({"key":key,"state":loaded["state"]})
    return result
func adopt_legacy(slot: int) -> String:
    var data: Dictionary=owner(slot)
    var loaded: Dictionary=load_slot(slot)
    if loaded["error"]!="":return loaded["error"]
    var old: Dictionary=Storage.restore_affinity(loaded["state"],legacy_checkpoints)
    if old["error"]!="":return old["error"]
    var newer: Dictionary=Storage.restore_affinity(old["state"],checkpoints(slot))
    if newer["error"]!="":return newer["error"]
    if FileAccess.file_exists(legacy_checkpoints+data["journey"]+".json"):
        var error: String=Storage.save_affinity(newer["state"],checkpoints(slot))
        if error!="":return error
        data["legacy_owned"]=true
    return write_json(directory(slot)+"owner.json",data)
func import_checkpoint(slot: int,key: String) -> String:
    if key.length()!=64 or not key.is_valid_hex_number() or bound(key):return "Este registro não está disponível para outra jornada."
    var loaded: Dictionary=Storage.load_state(legacy_checkpoints+key+".json",false)
    if loaded["error"]!="":return loaded["error"]
    if loaded["state"].affinity["phase"]=="unstarted":return "Este registro não contém uma avaliação iniciada."
    if Storage.affinity_key(loaded["state"])!=key:return "Identificação de avaliação inválida."
    var error: String=create(slot,loaded["state"])
    if error!="":return error
    error=adopt_legacy(slot)
    if error!="":return error
    if FileAccess.file_exists(legacy):
        var manual: Dictionary=Storage.load_state(legacy,false)
        if manual["error"]=="" and Storage.affinity_key(manual["state"])==key:return write_json(root+"legacy_migration.json",{"hash":FileAccess.get_sha256(legacy),"journey":key,"token":token(slot),"status":"done"})
    return ""
func migrate_legacy() -> String:
    if not FileAccess.file_exists(legacy):return ""
    var fingerprint: String=FileAccess.get_sha256(legacy)
    var receipt: Dictionary=read_json(root+"legacy_migration.json")
    if FileAccess.file_exists(root+"legacy_migration.json") and (receipt.get("status") not in ["pending","done"] or not receipt.get("hash") is String or not receipt.get("journey") is String or not receipt.get("token") is String):return "Registro de migração inválido; arquivos anteriores preservados."
    if receipt.get("status")=="done":return ""
    var old: Dictionary=Storage.load_state(legacy,false)
    if old["error"]!="":return "Salvamento anterior preservado: "+old["error"]
    old=Storage.restore_affinity(old["state"],legacy_checkpoints)
    if old["error"]!="":return old["error"]
    var state=old["state"]
    var key: String=Storage.affinity_key(state)
    if occupied(1):
        if owner(1).is_empty() and receipt.get("status")=="pending":
            var recovered: Dictionary=load_slot(1)
            if recovered["error"]!="":return recovered["error"]
        var data: Dictionary=owner(1)
        if receipt.get("status")!="pending" or receipt.get("hash")!=fingerprint or data.get("token")!=receipt.get("token") or data.get("journey")!=key or data.get("status")=="deleting":return "O arquivo anterior foi preservado. O Slot 1 já está ocupado."
        if not FileAccess.file_exists(path(1)):
            var error: String=Storage.save(state,path(1))
            if error!="":return error
            data["status"]="ready";error=write_json(directory(1)+"owner.json",data)
            if error!="":return error
    else:
        if receipt.get("status")!="pending" or receipt.get("hash")!=fingerprint:
            receipt={"hash":fingerprint,"journey":key,"token":Crypto.new().generate_random_bytes(16).hex_encode(),"status":"pending"}
            var error: String=write_json(root+"legacy_migration.json",receipt)
            if error!="":return error
        var error: String=create(1,state,receipt["token"])
        if error!="":return error
    var error: String=adopt_legacy(1)
    if error!="":return error
    var verified: Dictionary=load_slot(1)
    if verified["error"]!="":return verified["error"]
    receipt["status"]="done"
    error=write_json(root+"legacy_migration.json",receipt)
    return "Salvamento anterior migrado para o Slot 1. O original foi mantido." if error=="" else error
func delete_slot(slot: int,owner_token: String,confirmed: bool=false) -> String:
    if not confirmed:return "Confirme a exclusão da jornada."
    if not valid_slot(slot) or not occupied(slot) or token(slot)!=owner_token:return "O slot mudou desde a solicitação de exclusão."
    var data: Dictionary=owner(slot)
    var receipt: Dictionary=read_json(root+"legacy_migration.json")
    if receipt.get("token")==owner_token:
        receipt["status"]="done"
        var error: String=write_json(root+"legacy_migration.json",receipt)
        if error!="":return error
    data["token"]=owner_token;data["status"]="deleting"
    var error: String=write_json(directory(slot)+"owner.json",data)
    if error!="":return error
    # Somente arquivos do diretório fixo deste slot; não há remoção recursiva.
    if DirAccess.dir_exists_absolute(checkpoints(slot)):
        if not DirAccess.get_directories_at(checkpoints(slot)).is_empty():return "A pasta contém subpastas inesperadas; a exclusão foi interrompida."
        for file in DirAccess.get_files_at(checkpoints(slot)):
            if DirAccess.remove_absolute(checkpoints(slot)+file)!=OK:return "Não foi possível remover um checkpoint."
    if data.get("legacy_owned",false):
        var key: String=data.get("journey","")
        if key.length()!=64 or not key.is_valid_hex_number():return "Identificação antiga inválida; arquivos preservados."
        for suffix in [".json",".json.tmp"]:
            if FileAccess.file_exists(legacy_checkpoints+key+suffix) and DirAccess.remove_absolute(legacy_checkpoints+key+suffix)!=OK:return "Não foi possível remover o registro antigo da avaliação."
        if FileAccess.file_exists(legacy_checkpoints+"latest") and FileAccess.get_file_as_string(legacy_checkpoints+"latest").strip_edges()==key:DirAccess.remove_absolute(legacy_checkpoints+"latest")
    for file in [path(slot),path(slot)+".tmp",directory(slot)+"owner.json.tmp",directory(slot)+"owner.json"]:
        if FileAccess.file_exists(file) and DirAccess.remove_absolute(file)!=OK:return "Exclusão incompleta. Tente novamente."
    return ""
