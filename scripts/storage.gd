extends RefCounted
const State = preload("res://scripts/game_state.gd")
const PATH = "user://hunter_life.json"
const AFFINITY_DIR="user://affinity_checkpoints/"
static func save(state, path: String = PATH) -> String:
    if state.character_name.is_empty(): return "Crie um personagem primeiro."
    var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
    if not file: return "Não foi possível salvar."
    file.store_string(JSON.stringify(state.serialize())); file.flush()
    var code: Error = file.get_error(); file.close()
    if code!=OK or DirAccess.rename_absolute(path+".tmp",path)!=OK: return "Falha na gravação."
    return ""
static func integer(v: Variant, low: int, high: int) -> bool:
    return (v is int or v is float) and is_finite(float(v)) and float(v)==floor(float(v)) and v>=low and v<=high
static func load_state(path: String = PATH, respect_checkpoint: bool = true) -> Dictionary:
    var f = FileAccess.open(path,FileAccess.READ)
    if not f: return {"error":"Nenhuma partida salva encontrada."}
    var parser = JSON.new()
    if parser.parse(f.get_as_text())!=OK: return {"error":"Salvamento inválido."}
    var d: Variant = parser.data
    if not d is Dictionary: return {"error":"Salvamento inválido."}
    var s = State.new()
    if d.get("version")==2:
        if not d.get("seen") is Array: return {"error":"Eventos visitados inválidos."}
        if d.get("next") in ["end_home","end_path","end_duty"]: d["next"]="journey_"+str(d["next"]).trim_prefix("end_")
        if d.get("current") in ["end_home","end_path","end_duty"]: d["current"]="journey_"+str(d["current"]).trim_prefix("end_"); d["seen"].append(d["current"])
    for key in ["name","current","next","result","seed","rng"]:
        if not d.get(key) is String: return {"error":"Campo de texto inválido."}
    if not integer(d.get("version"),2,10) or d["name"].strip_edges().is_empty() or d["name"].length()>32 or not s.catalog.events.has(d["current"]): return {"error":"Identidade ou evento inválido."}
    if d["version"]>=10:
        if d.get("gender") not in ["unspecified","male","female"]:return {"error":"Gênero inválido."}
        s.gender=d["gender"]
    if d["next"]!="" and not s.catalog.events.has(d["next"]): return {"error":"Continuação inválida."}
    if not d.get("active") is bool or not d.get("attributes") is Dictionary or not d.get("flags") is Dictionary or not d.get("seen") is Array or not d.get("records") is Array: return {"error":"Estado incompleto."}
    if not integer(d.get("jenny"),0,1000000) or not integer(d.get("choice"),-1,s.catalog.events[d["current"]]["choices"].size()-1): return {"error":"Valores inválidos."}
    for key in State.INITIAL_ATTRIBUTES:
        if not integer(d["attributes"].get(key),1,10): return {"error":"Atributos inválidos."}
    for value in d["flags"].values():
        if not value is bool: return {"error":"Informação narrativa inválida."}
    var seen: Array = []
    for id in d["seen"]:
        if not id is String or not s.catalog.events.has(id) or id in seen: return {"error":"Eventos visitados inválidos."}
        seen.append(id)
    for line in d["records"]:
        if not line is String: return {"error":"Registro inválido."}
    if d["current"] not in seen or not d["seed"].is_valid_int() or not d["rng"].is_valid_int(): return {"error":"Continuidade inválida."}
    if d["choice"]==-1 and (d["next"]!="" or d["result"]!=""): return {"error":"Escolha inconsistente."}
    s.character_name=d["name"]; s.attributes=d["attributes"]; s.jenny=int(d["jenny"]); s.flags=d["flags"]; s.seen=seen
    s.current_id=d["current"]; s.demo=s.catalog.describe(s.current_id,s); s.selected_choice=int(d["choice"]); s.pending_next=d["next"]; s.active_adventure=d["active"]; s.result=d["result"]; s.records.assign(d["records"])
    for key in s.attributes: s.attributes[key]=int(s.attributes[key])
    s.rng.seed=int(d["seed"]); s.rng.state=int(d["rng"])
    if d["version"]>=3:
        if not integer(d.get("step"),1,100000) or not d.get("visits") is Dictionary or not d.get("last_visit") is Dictionary or not d.get("completed") is Array or not d.get("adventure") is String: return {"error":"Jornada inválida."}
        if d["visits"].size()!=seen.size() or d["last_visit"].size()!=seen.size(): return {"error":"Contadores incompletos."}
        for id in seen:
            if not integer(d["visits"].get(id),1,100000) or not integer(d["last_visit"].get(id),1,int(d["step"])): return {"error":"Repetição inválida."}
        for id in d["completed"]:
            if id not in s.catalog.adventures() or d["completed"].count(id)>1: return {"error":"Conclusão inválida."}
        if d["adventure"]!="" and d["adventure"] not in s.catalog.adventures() or d["active"]!=(d["adventure"]!=""): return {"error":"Aventura inconsistente."}
        s.visits=d["visits"];s.last_visit=d["last_visit"];s.step=int(d["step"]);s.completed=d["completed"];s.current_adventure=d["adventure"]
        for id in seen: s.visits[id]=int(s.visits[id]);s.last_visit[id]=int(s.last_visit[id])
    else:
        s.step=seen.size()
        for id in seen: s.visits[id]=1;s.last_visit[id]=s.step
        s.current_adventure="delivery" if s.active_adventure else ""
    if d["version"]>=4:
        if not integer(d.get("level"),1,10000 if d["version"]==4 else 20000) or not integer(d.get("xp"),0,(80+40*(int(d["level"])-1) if d["version"]==4 else State.Progress.threshold(int(d["level"])))-1) or not integer(d.get("points"),0,State.Progress.room(s)) or not integer(d.get("health"),0,10): return {"error":"Progressão ou Saúde inválida."}
        if int(d["points"])>int(d["level"])-1: return {"error":"Pontos incompatíveis com o nível."}
        if int(d["health"])==0 and (d["active"] or d["next"]!="" or int(d["choice"])<0): return {"error":"Jornada encerrada inconsistente."}
        s.level=int(d["level"]);s.xp=int(d["xp"]);s.points=int(d["points"]);s.health=int(d["health"])
    if d["version"]==4:
        # Total antigo: soma de 80+40*(k-1), para k=1..nível-1, mais saldo.
        var old_level: int=s.level
        var total: int=20*(old_level-1)*(old_level+2)+s.xp
        var old_points: int=s.points
        s.level=1;s.xp=0;s.points=0
        State.Progress.award(s,total)
        s.points=mini(State.Progress.room(s),old_points+s.level-old_level)
    if d["version"]>=5:
        if not State.Nen.valid(d.get("nen")):return {"error":"Estado de Nen inválido."}
        s.nen=d["nen"].duplicate(true)
        s.nen["mastery"]=int(s.nen["mastery"])
        for technique in ["ten","zetsu","ren"]:
            if s.flags.get("nen_"+technique,false)!=(technique in s.nen["techniques"]):return {"error":"Informações das técnicas inconsistentes."}
    if d["version"]<5:
        # Migração determina a afinidade sem avançar o RNG da narrativa antiga.
        var affinity_rng=RandomNumberGenerator.new()
        affinity_rng.seed=s.rng.seed;affinity_rng.state=s.rng.state
        s.nen["category"]=State.Nen.CATEGORIES[affinity_rng.randi_range(0,5)]
    if d["version"]>=6:
        var affinity_data: Variant=d.get("affinity",State.Affinity.fresh())
        if not State.Affinity.valid_data(affinity_data,s.catalog):return {"error":"Avaliação de afinidade inválida."}
        s.affinity=State.Affinity.normalized(affinity_data)
        if not State.Hatsu.valid(d.get("hatsu"),s):return {"error":"Hatsu incompatível ou inválido."}
        s.hatsu=d["hatsu"].duplicate(true)
    if d["version"]>=7:
        if not State.Battle.valid(d.get("battle"),s):return {"error":"Confronto inválido."}
        s.battle=d["battle"].duplicate(true)
        if not s.battle.is_empty():
            if s.selected_choice<0:return {"error":"Confronto fora do acontecimento."}
            var selected: Dictionary=s.demo["choices"][s.selected_choice]
            if s.battle["enemy"] not in [selected.get("battle",""),selected.get("failure",{}).get("battle","")]:return {"error":"Confronto fora do acontecimento."}
            for key in ["hp","turn","repeat","special_until"]:s.battle[key]=int(s.battle[key])
    if d["version"]>=8:
        if not State.Items.valid(d.get("inventory")):return {"error":"Inventário ou equipamento inválido."}
        s.inventory=d["inventory"].duplicate(true)
        s.inventory["revision"]=int(s.inventory["revision"])
        for id in s.inventory["items"]:s.inventory["items"][id]=int(s.inventory["items"][id])
    if d["version"]>=9:
        if not State.Exam.valid(d.get("exam"),s):return {"error":"Participação ou licença do exame inválida."}
        s.exam=d["exam"].duplicate(true);s.exam["stage"]=int(s.exam["stage"]);s.exam["setbacks"]=int(s.exam["setbacks"])
    elif s.Items.quantity(s,"hunter_license")>0:return {"error":"Licença sem aprovação registrada."}
    s.missions=d.get("missions",{}) if d["version"]>=10 else State.Missions.migrate(s)
    if not State.Missions.valid(s.missions,s):return {"error":"Continuidade de missão inválida."}
    if not State.Affinity.valid_state(s):return {"error":"Continuidade da avaliação inválida."}
    if respect_checkpoint and path==PATH:return restore_affinity(s)
    return {"state":s,"error":""}

static func affinity_key(s) -> String:
    # Nome imutável e semente de nascimento identificam a jornada, sem consumir RNG.
    return (str(s.rng.seed)+":"+s.character_name).sha256_text()
static func save_affinity(s,directory: String=AFFINITY_DIR) -> String:
    if s.affinity["phase"]=="unstarted":return ""
    if DirAccess.make_dir_recursive_absolute(directory)!=OK:return "Não foi possível registrar a avaliação."
    var key: String=affinity_key(s)
    var error: String=save(s,directory+key+".json")
    if error!="":return error
    var f=FileAccess.open(directory+"latest.tmp",FileAccess.WRITE)
    if not f:return "Não foi possível registrar a retomada da avaliação."
    f.store_string(key);f.flush();var code: Error=f.get_error();f.close()
    if code!=OK or DirAccess.rename_absolute(directory+"latest.tmp",directory+"latest")!=OK:return "Não foi possível registrar a retomada da avaliação."
    return ""
static func restore_affinity(s,directory: String=AFFINITY_DIR) -> Dictionary:
    var path: String=directory+affinity_key(s)+".json"
    if not FileAccess.file_exists(path):return {"state":s,"error":""}
    var loaded: Dictionary=load_state(path,false)
    if loaded["error"]!="":return {"error":"O registro da avaliação não pôde ser lido. "+loaded["error"]}
    var checkpoint=loaded["state"]
    if affinity_key(checkpoint)!=affinity_key(s):return {"error":"Registro de avaliação de outra jornada."}
    var phases: Array=["unstarted","active","resolved","learned"]
    var checkpoint_progress: int=phases.find(checkpoint.affinity["phase"])*10+checkpoint.affinity["decisions"].size()
    var progress: int=phases.find(s.affinity["phase"])*10+s.affinity["decisions"].size()
    if checkpoint.step>s.step or checkpoint.step==s.step and checkpoint_progress>progress:return loaded
    return {"state":s,"error":""}
static func latest_affinity(directory: String=AFFINITY_DIR) -> Dictionary:
    var key: String=FileAccess.get_file_as_string(directory+"latest").strip_edges() if FileAccess.file_exists(directory+"latest") else ""
    if key.length()!=64 or not key.is_valid_hex_number():return {"error":"Nenhum registro de avaliação disponível."}
    var checkpoint: Dictionary=load_state(directory+key+".json",false)
    if directory==AFFINITY_DIR and checkpoint["error"]=="" and FileAccess.file_exists(PATH):
        var manual: Dictionary=load_state(PATH,false)
        if manual["error"]=="" and affinity_key(manual["state"])==affinity_key(checkpoint["state"]):return restore_affinity(manual["state"],directory)
    return checkpoint
