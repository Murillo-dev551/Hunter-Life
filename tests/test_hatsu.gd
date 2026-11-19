extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func ready_state(category: String):
    var s=State.new();s.rng.seed=6006;s.start("Hatsu")
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"category":category,"water_done":true}
    for t in ["ten","zetsu","ren"]:s.flags["nen_"+t]=true
    return s
func run() -> void:
    var s=State.new();s.start("Sem requisitos");s.open_event("develop_reinforce")
    check(not s.choose(0),"Sem desbloqueio inicial")
    var specs: Dictionary={"reinforce":["power","resistance"],"emission":["power","range","precision"]}
    for id in specs:
        for index in range(specs[id].size()):
            s=ready_state("Reforço" if id=="reinforce" else "Emissão")
            s.open_event("develop_"+id)
            check(s.choose(index) and s.hatsu["learned"] and s.hatsu["specialization"]==specs[id][index],"Especialização escolhida")
            check(not s.choose(index),"Resultado único")
            Store.save(s,"user://test_hatsu.json")
            var loaded=Store.load_state("user://test_hatsu.json")
            check(loaded["error"]=="" and loaded["state"].serialize()==s.serialize(),"Save v6 preserva Hatsu e categoria")
            check(not loaded["state"].choose(index) and loaded["state"].serialize()==s.serialize(),"Carregar não duplica aprendizado ou XP")
            s.open_event("develop_"+id)
            check(not s.choose((index+1)%specs[id].size()),"Sem troca livre")
            var application: String="blocked_passage" if id=="reinforce" or specs[id][index]=="power" else "signal_roof"
            s.open_event(application)
            var found: int=0
            for i in range(s.demo["choices"].size()):
                if s.demo["choices"][i].get("conditions",{}).has("hatsu") and s.choice_reason(i)=="":found+=1
            check(found==1,"Aplicação específica da especialização")
    s=ready_state("Manipulação");s.open_event("develop_emission")
    check(not s.choose(0),"Outra categoria não aprende Hatsu implementado")
    s=ready_state("Emissão");s.nen["water_done"]=false;s.open_event("develop_emission")
    check(not s.choose(0),"Categoria não revelada bloqueia")
    s=ready_state("Reforço")
    var old: Dictionary=s.serialize().duplicate(true);old["version"]=5;old.erase("hatsu")
    var f=FileAccess.open("user://test_hatsu.json",FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
    var migrated=Store.load_state("user://test_hatsu.json")
    check(migrated["error"]=="" and not migrated["state"].hatsu["learned"] and migrated["state"].nen==s.nen,"Migração v5 sem Hatsu e sem rerrolagem")
    check(s.Progress.chance(5,12)>s.Progress.chance(5,15),"Potência reduz dificuldade específica")
    var invalid: Dictionary=s.serialize().duplicate(true)
    invalid["hatsu"]={"learned":true,"id":"emission","specialization":"range"}
    f=FileAccess.open("user://test_hatsu.json",FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state("user://test_hatsu.json")["error"]!="","Save com Hatsu de categoria diferente recusado")
    var outcomes: Dictionary={}
    for seed_value in range(40):
        s=ready_state("Reforço");s.hatsu={"learned":true,"id":"reinforce","specialization":"resistance"};s.open_event("blocked_passage");s.rng.seed=seed_value
        var hp: int=s.health
        s.choose(3)
        check(s.health>=hp-1,"Resistência limita esse impacto")
        outcomes["failure" if s.health<hp else "success"]=true
    check(outcomes.size()==2,"Hatsu não garante sucesso")
    var learning: Dictionary={}
    for seed_value in range(40):
        s=ready_state("Reforço");s.nen["techniques"]=["ten"];s.nen["mastery"]=1;s.flags.erase("nen_zetsu");s.flags.erase("nen_ren");s.nen["water_done"]=false
        s.open_event("nen_zetsu");s.rng.seed=seed_value;s.choose(0)
        learning["guided" if s.flags.get("zetsu_guided",false) else "success"]=true
        check("zetsu" in s.nen["techniques"] and s.advance() and s.current_id=="nen_ren","Falha não exige repetição infinita")
    check(learning.size()==2,"Sucesso e fracasso de Nen distintos")
    var levels: Dictionary={}
    for use_hatsu in [false,true]:
        var group: Dictionary={}
        for n in range(50):
            s=ready_state("Reforço" if n%2==0 else "Emissão");s.rng.seed=n
            if use_hatsu:
                s.open_event("develop_reinforce" if n%2==0 else "develop_emission");s.choose(n%(2 if n%2==0 else 3));s.advance()
            else:
                s.flags["nen_declined"]=true
            var steps: int=0
            while s.health>0 and s.demo["kind"]!="ending" and steps<100:
                var options: Array=[]
                for i in range(s.demo["choices"].size()):
                    if s.choice_reason(i)=="" and not s.demo["choices"][i].has("hatsu_learn"):options.append(i)
                if options.is_empty():check(false,"Sem bloqueio");break
                s.choose(options[s.rng.randi_range(0,options.size()-1)]);s.advance();steps+=1
            check(steps<100 and (s.health==0 or s.demo["kind"]=="ending"),"Jornada com ou sem Hatsu conclui")
            group[s.level]=int(group.get(s.level,0))+1
        levels["com_hatsu" if use_hatsu else "sem_hatsu"]=group
    print("HATSUS: %d verificações, %d falhas; jornadas=%s" % [checks,failures,levels])
    DirAccess.remove_absolute("user://test_hatsu.json")
    quit(1 if failures else 0)

