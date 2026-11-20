extends SceneTree
const Driver=preload("res://tests/battle_driver.gd")
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func write(data: Dictionary) -> void:
    var f=FileAccess.open("user://test_nen.json",FileAccess.WRITE);f.store_string(JSON.stringify(data));f.close()
func learn(s, water: bool=true) -> void:
    s.open_event("nen_offer");s.choose(0);s.advance()
    for i in range(3):
        check(s.choose(0),"Aprendizado permitido");s.advance()
    check(s.nen["mastery"]==3 and s.nen["techniques"].size()==3,"Três marcos, sem repetição")
    if water:s.choose(0);s.advance()
func run() -> void:
    var s=State.new();s.start("Migração")
    var old: Dictionary=s.serialize().duplicate(true);old["version"]=4;old.erase("nen")
    old["level"]=3;old["xp"]=50;old["points"]=1;old["attributes"]["strength"]=6
    write(old)
    var migrated=Store.load_state("user://test_nen.json")
    check(migrated["error"]=="","Migra v4")
    var m=migrated["state"]
    check(m.level==4 and m.xp==70 and m.points==2 and m.attributes["strength"]==6,"250 XP totais, pontos gastos preservados")
    check(not m.nen["awakened"] and not m.nen["water_done"],"Sem Nen retroativo")
    for level in range(1,15):
        old["level"]=level;old["xp"]=17;old["points"]=0;write(old)
        m=Store.load_state("user://test_nen.json")["state"]
        var before: int=20*(level-1)*(level+2)+17
        var after: int=10*(m.level-1)*(m.level+2)+m.xp
        check(before==after,"XP total preservado")
    var extreme: Dictionary=old.duplicate(true)
    extreme["level"]=10000;extreme["xp"]=0
    write(extreme)
    var high=Store.load_state("user://test_nen.json")
    check(high["error"]=="","Limite legado válido migra")
    Store.save(high["state"],"user://test_nen.json")
    check(Store.load_state("user://test_nen.json")["error"]=="","Nível migrado alto continua válido em v5")
    Store.save(m,"user://test_nen.json")
    var stable=Store.load_state("user://test_nen.json")
    check(stable["error"]=="" and stable["state"].serialize()==m.serialize(),"v5 não migra XP novamente")
    s.start("Categoria fixa")
    var fixed: String=s.nen["category"]
    for i in range(20):s.rng.randi()
    learn(s,false)
    check(s.nen["category"]==fixed,"Afinidade não muda ao consumir sorteios antes de aprender")
    s.start("Recusa");s.open_event("nen_offer");s.choose(2);s.advance()
    check(not s.nen["awakened"] and s.demo["kind"]!="ending" and not s.catalog.eligible(s.catalog.events["nen_offer"]["conditions"],s),"Recusar não encerra jornada")
    s.start("Adiar");s.open_event("nen_offer");s.choose(1);s.advance();s.step+=4
    check(not s.catalog.available("nen_offer",s),"Convite adiado não volta ao sorteio")
    s.open_event("nen_ten")
    check(s.current_id=="nen_ten","Retomar o aprendizado segue à cena ainda pendente")
    var categories: Dictionary={}
    for n in range(100):
        s=State.new();s.rng.seed=n;s.start("Água")
        learn(s,false)
        var category: String=s.nen["category"]
        check(not s.nen["water_done"],"Categoria não revelada antes do teste")
        Store.save(s,"user://test_nen.json")
        var loaded=Store.load_state("user://test_nen.json")
        check(loaded["error"]=="","Salva antes da água")
        var other=loaded["state"]
        s.choose(0);other.choose(0)
        check(s.nen==other.nen and s.result==other.result,"Água idêntica após carregar")
        Store.save(s,"user://test_nen.json")
        var revealed=Store.load_state("user://test_nen.json")
        check(revealed["error"]=="" and revealed["state"].nen["water_done"] and revealed["state"].nen["category"]==category and not revealed["state"].choose(0),"Revelação e resultado persistem sem duplicação")
        s.advance();s.open_event("nen_water")
        check(not s.choose(0) and s.nen["category"]==category,"Sem rerrolagem")
        categories[category]=int(categories.get(category,0))+1
    check(categories.size()==6,"Seis categorias sorteadas")
    s=State.new();s.start("Condições")
    for pair in [["bridge","nen_ten"],["survey_find","nen_zetsu"],["tournament","nen_ren"]]:
        s.open_event(pair[0]);var index: int=0
        for i in range(s.demo["choices"].size()):
            if s.demo["choices"][i].get("conditions",{}).get("flags",{}).get(pair[1],false):index=i
        check(s.choice_reason(index)!="","Técnica bloqueada antes de aprender")
    learn(s)
    for pair in [["bridge","nen_ten"],["survey_find","nen_zetsu"],["tournament","nen_ren"]]:
        s.open_event(pair[0]);var index: int=0
        for i in range(s.demo["choices"].size()):
            if s.demo["choices"][i].get("conditions",{}).get("flags",{}).get(pair[1],false):index=i
        check(s.choice_reason(index)=="","Técnica abre alternativa")
    var old_chance: int=s.Progress.chance(s.attributes["agility"],16)
    s.Progress.award(s,40);s.Progress.spend(s,"agility")
    check(s.Progress.chance(s.attributes["agility"],16)==old_chance+5,"Ponto atualiza chance em 5 pontos percentuais")
    var journeys: Dictionary={}
    for use_nen in [false,true]:
        var levels: Dictionary={}
        for seed_value in range(50):
            s=State.new();s.rng.seed=seed_value;s.start("Caminho")
            if use_nen:learn(s);s.choose(0);s.advance()
            else:
                s.flags["nen_declined"]=true
                if s.current_id=="nen_offer":s.choose(2);s.advance()
            var steps: int=0
            while s.health>0 and s.demo["kind"]!="ending" and steps<100:
                var options: Array=[]
                for i in range(s.demo["choices"].size()):
                    if s.choice_reason(i)=="":options.append(i)
                if options.is_empty():check(false,"Jornada sem bloqueio");break
                s.choose(options[s.rng.randi_range(0,options.size()-1)]);Driver.resolve(s);s.advance();steps+=1
            check(steps<100 and (s.demo["kind"]=="ending" or s.health==0),"Jornada com ou sem Nen chega a conclusão")
            levels[s.level]=int(levels.get(s.level,0))+1
        journeys["com_nen" if use_nen else "sem_nen"]=levels
    print("JORNADAS COM/SEM NEN: ",journeys)
    print("NEN: %d verificações, %d falhas; categorias=%s" % [checks,failures,categories])
    DirAccess.remove_absolute("user://test_nen.json")
    quit(1 if failures else 0)





