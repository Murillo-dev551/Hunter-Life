extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const PATH="user://test_affinity.json"
const DIRECTORY="user://test_affinity_checkpoints/"
var checks: int=0
var failures: int=0
var files: Array[String]=[]
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func ready(seed_value: int=0):
    var s=State.new();s.rng.seed=seed_value;s.start("Especialista");s.active_adventure=false;s.current_adventure=""
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Especialização"}
    for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
    s.open_event("affinity_offer");return s
func snapshot(s):
    check(Store.save(s,PATH)=="","Salva avaliação")
    var loaded=Store.load_state(PATH)
    check(loaded["error"]=="","Carrega avaliação: "+loaded["error"])
    if loaded["error"]!="":return s
    check(loaded["state"].serialize()==s.serialize(),"Estado e RNG preservados")
    return loaded["state"]
func commit(s) -> void:
    check(Store.save_affinity(s,DIRECTORY)=="","Checkpoint registrado")
    var path: String=DIRECTORY+Store.affinity_key(s)+".json"
    if path not in files:files.append(path)
func evaluate(id: String,seed_value: int=0,persist: bool=true):
    var s=ready(seed_value)
    check(s.choose(0),"Inicia avaliação opcional")
    var before=s.serialize().duplicate(true)
    check(not s.choose(0) and s.serialize()==before,"Não duplica início")
    s.advance()
    for stage in range(5):
        check(s.current_id=="affinity_trial_%d" % (stage+1),"Cinco cenas na ordem")
        var current: String=s.current_id
        s.open_event("market");s.open_event(current)
        check(s.current_id==current and s.selected_choice==-1,"Não cancela nem reinicia cena")
        var index: int=-1
        for i in range(5):
            if s.demo["choices"][i]["affinity_style"]==id:index=i
        check(s.choose(index),"Decisão pertinente")
        before=s.serialize().duplicate(true)
        check(not s.choose(index) and before==s.serialize(),"Não duplica decisão ou rolagem")
        if persist:s=snapshot(s)
        check(s.advance(),"Prossegue mesmo após fracasso")
        if persist:s=snapshot(s)
    check(s.affinity["result"]==id and s.affinity["phase"]=="resolved","Cinco afinidades alcançáveis por decisões")
    check(s.nen["category"]=="Especialização" and not s.hatsu["learned"],"Revelação não altera categoria nem escolhe especialização")
    var revealed: Dictionary=s.serialize().duplicate(true)
    s.open_event("affinity_trial_1");s.open_event("develop_emission")
    check(s.serialize()==revealed,"Depois da revelação não retorna à avaliação nem escolhe outro Hatsu")
    return s
func run() -> void:
    var catalog=State.new().catalog
    for stage in range(5):
        var styles: Array=[]
        for choice in catalog.events["affinity_trial_%d" % (stage+1)]["choices"]:styles.append(choice["affinity_style"])
        styles.sort()
        var expected: Array=State.Affinity.IDS.duplicate();expected.sort()
        check(styles==expected,"Mesma representação das cinco afinidades em cada cena")
    var success: int=0
    var failure: int=0
    for id in State.Affinity.IDS:
        for index in range(State.Hatsu.SPECS[id].size()):
            var s=evaluate(id,10+index)
            for decision in s.affinity["decisions"]:
                if decision["success"]:success+=1
                else:failure+=1
            check(s.choose(index) and s.hatsu["id"]==id and s.hatsu["specialization"]==s.Hatsu.SPECS[id][index],"Escolha interna permanente")
            s=snapshot(s)
            check(not s.Affinity.eligible(s),"Avaliação não volta a ficar disponível")
            s.open_event("affinity_offer");check(not s.choose(0),"Não reinicia após conhecer resultado")
            s.open_event("develop_"+id);check(not s.choose(0),"Não troca habilidade ou direção")
            var native=State.new();native.start("Original");native.active_adventure=false;native.current_adventure=""
            native.nen=s.nen.duplicate(true);native.nen["category"]=s.Hatsu.category(id)
            native.hatsu=s.hatsu.duplicate(true);native.attributes=s.attributes.duplicate()
            for technique in native.nen["techniques"]:native.flags["nen_"+technique]=true
            s.open_event("battle_bandit");native.open_event("battle_bandit");s.choose(0);native.choose(0)
            native.rng.seed=s.rng.seed;native.rng.state=s.rng.state
            for action in s.Battle.LABELS:check(s.Battle.test(s,action)==native.Battle.test(native,action),"Mesmos testes da categoria original")
            check(s.Battle.act(s,"hatsu",1) and native.Battle.act(native,"hatsu",1),"Especialista usa o motor existente")
            check(s.health==native.health and s.battle==native.battle,"Mesmo dano, proteção, alvo, cooldown e RNG")
            s=snapshot(s)
            check(s.nen["category"]=="Especialização","Categoria permanece após combate e carregamento")
            var contexts: int=0
            for event in s.catalog.events.values():
                for choice in event["choices"]:
                    var conditions: Dictionary=choice.get("conditions",{})
                    if conditions.has("hatsu"):
                        check(s.catalog.eligible(conditions,s)==native.catalog.eligible(conditions,native),"Mesmas alternativas narrativas")
                        if s.catalog.eligible(conditions,s):contexts+=1
                        if conditions["hatsu"]["id"]!=id:check(not s.catalog.eligible(conditions,s),"Não acessa os outros Hatsus")
            check(contexts>0,"Aplicação narrativa da especialização disponível")
    check(success>0 and failure>0,"Avaliações cobrem sucessos e fracassos")
    var s=ready()
    for category in s.Nen.CATEGORIES:
        s=ready();s.nen["category"]=category
        check(s.Affinity.eligible(s)==(category=="Especialização"),"Categoria exigida")
    s=ready();s.nen["water_done"]=false;check(not s.choose(0),"Revelação exigida")
    s=ready();s.nen["mastery"]=2;check(not s.choose(0),"Fundamentos exigidos")
    s=ready();check(s.choose(1) and s.affinity["phase"]=="unstarted","Pode recusar antes de iniciar")
    var scores: Dictionary=State.Affinity.fresh()["scores"]
    var decisions: Array=[]
    for id in State.Affinity.IDS:scores[id]=3;decisions.append({"style":id})
    var attributes: Dictionary=State.INITIAL_ATTRIBUTES.duplicate()
    attributes["intellect"]=8
    check(State.Affinity.choose_result(scores,decisions,attributes)=="conjuration","Desempate por atributo após história recente")
    attributes["intellect"]=5
    check(State.Affinity.choose_result(scores,decisions,attributes)=="manipulation","Desempate final pela decisão mais recente")
    scores={"reinforce":9,"emission":8,"transmutation":0,"conjuration":0,"manipulation":0}
    check(State.Affinity.choose_result(scores,[{"style":"reinforce"},{"style":"reinforce"},{"style":"reinforce"},{"style":"emission"},{"style":"emission"}],attributes)=="reinforce","Três intenções fracassadas superam duas bem-sucedidas")
    # O slot manual antigo continua intacto; o checkpoint promove somente a mesma jornada.
    s=ready(909);var old=snapshot(s);var manual_hash: String=FileAccess.get_sha256(PATH)
    s.choose(0);s.advance();s.choose(0);commit(s)
    check(FileAccess.get_sha256(PATH)==manual_hash,"Checkpoint não sobrescreve o slot manual")
    var restored=Store.restore_affinity(old,DIRECTORY)
    check(restored["error"]=="" and restored["state"].serialize()==s.serialize(),"Carregar ponto anterior não reinicia avaliação")
    var latest=Store.latest_affinity(DIRECTORY)
    check(latest["error"]=="" and latest["state"].serialize()==s.serialize(),"Retoma mesmo sem slot manual")
    var different=ready(910)
    check(Store.restore_affinity(different,DIRECTORY)["state"].serialize()==different.serialize(),"Checkpoint não substitui outra jornada")
    s=restored["state"];s.advance();s.choose(0);commit(s)
    check(Store.restore_affinity(old,DIRECTORY)["state"].affinity["decisions"].size()==2,"Checkpoint avança sem repetir rolagens")
    s.advance()
    check(Store.restore_affinity(s,DIRECTORY)["state"].serialize()==s.serialize(),"Salvamento mais recente não volta ao checkpoint antigo")
    # Save v9 da 10D não tem o novo campo, mas preserva categoria e histórico.
    var previous=ready();previous.open_event("market")
    var data: Dictionary=previous.serialize().duplicate(true);data.erase("affinity")
    var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
    var migrated=Store.load_state(PATH)
    check(migrated["error"]=="" and migrated["state"].affinity==State.Affinity.fresh() and migrated["state"].nen==previous.nen,"Migração opcional v9 sem avaliação retroativa")
    s=evaluate("reinforce",99,false);s.choose(0)
    commit(s)
    check(Store.restore_affinity(ready(99),DIRECTORY)["state"].serialize()==s.serialize(),"Resultado e especialização definitivos sobrevivem ao carregamento anterior")
    data=s.serialize().duplicate(true);data["affinity"]["result"]="emission"
    f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
    check(Store.load_state(PATH)["error"]!="","Resultado adulterado rejeitado")
    s=ready();s.choose(0)
    data=s.serialize().duplicate(true);data["flags"]["affinity_completed"]=true
    f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
    check(Store.load_state(PATH)["error"]!="","Conclusão antecipada incompatível rejeitada")
    var distribution: Dictionary={}
    for seed_value in range(200):
        s=ready(seed_value);s.choose(0);s.advance()
        for stage in range(5):s.choose(s.rng.randi_range(0,4));s.advance()
        var id: String=s.affinity["result"]
        distribution[id]=int(distribution.get(id,0))+1
    check(distribution.size()==5,"Amostra de decisões variadas alcança as cinco afinidades")
    print("AFINIDADE 10E: %d verificações, %d falhas; resultados=%s; testes dirigidos=%d sucessos/%d fracassos" % [checks,failures,distribution,success,failure])
    DirAccess.remove_absolute(PATH)
    for path in files:DirAccess.remove_absolute(path)
    DirAccess.remove_absolute(DIRECTORY+"latest")
    quit(1 if failures else 0)
