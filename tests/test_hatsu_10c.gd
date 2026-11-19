extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const PATH="user://test_hatsu_10c.json"
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func ready(id: String,spec: String="",seed_value: int=0):
    var s=State.new();s.rng.seed=seed_value;s.start("Aprendiz")
    s.active_adventure=false;s.current_adventure=""
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":s.Hatsu.category(id)}
    for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
    if spec!="":s.hatsu={"id":id,"specialization":spec,"learned":true}
    return s
func load_same(s):
    check(Store.save(s,PATH)=="","Salva")
    var loaded=Store.load_state(PATH)
    check(loaded["error"]=="","Carrega")
    if loaded["error"]!="":return s
    check(loaded["state"].serialize()==s.serialize(),"RNG, Hatsu e dados preservados")
    return loaded["state"]
func battle(id: String,spec: String,seed_value: int=0):
    var s=ready(id,spec,seed_value);s.open_event("battle_fighter");s.choose(0);s.battle["intent"]="charge";return s
func run() -> void:
    for id in ["transmutation","conjuration"]:
        var outcomes: Dictionary={}
        for seed_value in range(20):
            var learner=ready(id,"",seed_value);learner.open_event("develop_"+id);learner.choose(0)
            check(learner.hatsu["learned"],"Fracasso assistido também conclui aprendizado")
            outcomes[learner.result.contains("· sucesso")]=true
        check(outcomes.size()==2,"Aprendizado cobre sucesso e orientação após fracasso")
        for index in range(2):
            var s=ready(id);s.open_event("develop_"+id)
            var category: String=s.nen["category"]
            check(s.choose(index) and s.hatsu["learned"],"Aprende especialização sem licença")
            var before: Dictionary=s.serialize().duplicate(true)
            check(not s.choose(index) and before==s.serialize(),"Escolha não duplica XP")
            s=load_same(s)
            check(s.nen["category"]==category,"Carregar não altera categoria")
            s.open_event("develop_"+id)
            check(not s.choose(1-index),"Não troca especialização")
        for category in State.Nen.CATEGORIES:
            var s=ready(id);s.nen["category"]=category;s.open_event("develop_"+id)
            check((s.choice_reason(0)=="")==(category==s.Hatsu.category(id)),"Afinidade correta exigida")
        var s=ready(id);s.nen["water_done"]=false;s.open_event("develop_"+id)
        check(not s.choose(0),"Sem revelação não aprende")
        s=ready(id);s.nen["mastery"]=1;s.open_event("develop_"+id)
        check(not s.choose(0),"Fundamentos incompletos não aprendem")
    var totals: Dictionary={}
    for id in ["transmutation","conjuration"]:
        for spec in State.Hatsu.SPECS[id]:
            var successes: int=0
            var failed: int=0
            for seed_value in range(60):
                var s=battle(id,spec,seed_value)
                var hp: int=s.battle["hp"]
                var test: Dictionary=s.Battle.test(s,"hatsu")
                var expected: int=s.Progress.chance(s.attributes[test["attribute"]],test["difficulty"])
                check(expected>=0 and expected<=100,"Mesma probabilidade d20")
                check(s.Battle.act(s,"hatsu",1),"Resolve ação")
                if s.result.contains("· sucesso"):
                    successes+=1
                    if id=="transmutation":
                        check(s.battle["opening"] and s.battle["hp"]==hp-(1 if spec=="restraint" else 0),"Fio cria abertura com dano específico")
                        check(s.health==(8 if spec=="restraint" else 9),"Contenção e Mobilidade protegem diferentemente")
                    else:
                        check(s.health==(10 if spec=="resistance" else 9),"Escudo reduz dano compatível")
                        check(s.battle["opening"]==(spec=="coverage"),"Cobertura desvia investida; Resistência não cria abertura")
                else:
                    failed+=1
                    check(not s.battle["opening"],"Falha não deixa abertura")
                    check(s.health==(8 if id=="conjuration" and spec=="resistance" else 7),"Falha tem consequência explícita")
                check(s.Battle.reason(s,"hatsu")!="" and s.Battle.reason(s,"ten")!="","Intervalo compartilhado bloqueia aura consecutiva")
                if seed_value<3:
                    var clone=load_same(s)
                    s.Battle.act(s,"attack",2);clone.Battle.act(clone,"attack",2)
                    check(s.serialize()==clone.serialize(),"Mesmo turno após carregar")
                    check(s.Battle.reason(s,"hatsu")=="" or not s.Battle.active(s),"Ação comum recupera uso")
            check(successes>0 and failed>0,"Amostra cobre sucesso e fracasso")
            var wins: int=0
            var longest: int=0
            var turns: int=0
            for seed_value in range(100):
                var s=battle(id,spec,seed_value)
                while s.Battle.active(s) and s.battle["turn"]<40:
                    var action: String="hatsu" if s.Battle.reason(s,"hatsu")=="" else "attack"
                    s.Battle.act(s,action,s.battle["turn"])
                    check(s.health>=0 and s.health<=10,"Saúde limitada")
                check(not s.Battle.active(s),"Estratégia termina")
                if s.battle["outcome"] in ["victory","enemy_yield"]:wins+=1
                turns+=s.battle["turn"];longest=maxi(longest,s.battle["turn"])
            totals[id+":"+spec]={"wins":wins,"mean_turns":turns/100.0,"max_turns":longest,"success":successes,"failure":failed}
            var tactical_wins: int=0
            var tactical_turns: int=0
            for seed_value in range(100):
                var tactical=battle(id,spec,seed_value)
                while tactical.Battle.active(tactical) and tactical.battle["turn"]<40:
                    var action: String="hatsu" if tactical.battle["intent"] in ["charge","strike"] and tactical.Battle.reason(tactical,"hatsu")=="" else "attack"
                    tactical.Battle.act(tactical,action,tactical.battle["turn"])
                check(not tactical.Battle.active(tactical),"Uso contextual termina")
                if tactical.battle["outcome"]=="victory":tactical_wins+=1
                tactical_turns+=tactical.battle["turn"]
            totals[id+":"+spec]["contextual_wins"]=tactical_wins
            totals[id+":"+spec]["contextual_mean_turns"]=tactical_turns/100.0
            var defensive=battle(id,spec,2)
            while defensive.Battle.active(defensive) and defensive.battle["turn"]<40:
                defensive.Battle.act(defensive,"hatsu" if defensive.Battle.reason(defensive,"hatsu")=="" else "defend",defensive.battle["turn"])
            check(not defensive.Battle.active(defensive),"Alternar proteção não cria defesa infinita")
    for pair in [["signal_roof","transmutation","mobility"],["exam_capture","transmutation","restraint"],["ruins_entry","transmutation","mobility"],["blocked_passage","conjuration","resistance"],["exam_team","conjuration","coverage"],["reservoir","conjuration","coverage"]]:
        var s=ready(pair[1],pair[2]);s.open_event(pair[0])
        if pair[0].begins_with("exam_"):
            s.exam={"status":"active","sequence":["exam_crossing","exam_capture","exam_team","exam_judgment"],"stage":2 if pair[0]=="exam_capture" else 3,"setbacks":0,"awarded":false}
        var index: int=-1
        for i in range(s.demo["choices"].size()):
            if s.demo["choices"][i].get("conditions",{}).get("hatsu",{})=={"id":pair[1],"specialization":pair[2]}:index=i
        check(s.choice_reason(index)=="" and s.choose(index),"Alternativa narrativa disponível")
        check(s.result!="","Resultado contextual apresentado")
        s=load_same(s)
        var other=ready(pair[1],"restraint" if pair[2]=="mobility" else "mobility" if pair[1]=="transmutation" else "coverage" if pair[2]=="resistance" else "resistance")
        other.open_event(pair[0])
        check(other.choice_reason(index)!="","Outra especialização não substitui a necessária")
    var old=ready("reinforce","resistance");old.open_event("market");old=load_same(old)
    check(old.hatsu["id"]=="reinforce" and old.serialize()["version"]==9,"Save v9 anterior preservado")
    var invalid: Dictionary=old.serialize().duplicate(true)
    invalid["hatsu"]={"id":"conjuration","specialization":"coverage","learned":true}
    var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state(PATH)["error"]!="","Save com afinidade incompatível rejeitado")
    for id in ["transmutation","conjuration"]:
        var s=ready(id)
        check(not s.Hatsu.valid({"id":id,"specialization":"inexistente","learned":true},s),"Especialização inválida rejeitada")
    print("HATSUS 10C: %d verificações, %d falhas; simulações=%s" % [checks,failures,totals])
    DirAccess.remove_absolute(PATH)
    quit(1 if failures else 0)
