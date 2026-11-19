extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const PATH="user://test_manipulation.json"
const BASELINE="021ced9bea2ae52155c5593e7268c026f525f78bee57931ddfd41c2247a15118"
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func ready(spec: String="",seed_value: int=0):
    var s=State.new();s.rng.seed=seed_value;s.start("Aprendiz");s.active_adventure=false;s.current_adventure=""
    s.nen={"awakened":true,"techniques":["ten","zetsu","ren"],"mastery":3,"water_done":true,"category":"Manipulação"}
    for technique in s.nen["techniques"]:s.flags["nen_"+technique]=true
    if spec!="":s.hatsu={"id":"manipulation","specialization":spec,"learned":true}
    return s
func snapshot(s):
    check(Store.save(s,PATH)=="","Salva")
    var loaded=Store.load_state(PATH)
    check(loaded["error"]=="","Carrega: "+loaded["error"])
    if loaded["error"]!="":return s
    check(loaded["state"].serialize()==s.serialize(),"Preserva estado, RNG e consequências")
    return loaded["state"]
func battle(spec: String,enemy: String,seed_value: int=0):
    var s=ready(spec,seed_value)
    s.open_event("exam_duel" if enemy=="candidate" else "battle_"+enemy)
    if enemy=="candidate":s.exam={"status":"active","sequence":["exam_crossing","exam_capture","exam_team","exam_duel"],"stage":4,"setbacks":0,"awarded":false}
    s.choose(0);s.battle["intent"]="charge";return s
func run() -> void:
    var data: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json"))
    var previous: Array=data.slice(0,80).duplicate(true)
    var counts: Dictionary={"signal_roof":5,"reservoir":4,"exam_capture":5,"escort_checkpoint":5}
    for event in previous:
        if counts.has(event["id"]):event["choices"]=event["choices"].slice(0,counts[event["id"]])
    check(data.size()==92 and JSON.stringify(previous).sha256_text()==BASELINE,"Preserva integralmente os 80 acontecimentos e escolhas anteriores")
    for spec in ["objects","motor"]:
        var outcomes: Dictionary={}
        for seed_value in range(30):
            var s=ready("",seed_value);s.open_event("develop_manipulation")
            check(s.choose(0 if spec=="objects" else 1) and s.hatsu["specialization"]==spec,"Aprende especialização sem nível ou licença")
            outcomes[s.result.contains("· sucesso")]=true
            var before: Dictionary=s.serialize().duplicate(true)
            check(not s.choose(0) and before==s.serialize(),"Não duplica aprendizado ou XP")
            s=snapshot(s);s.open_event("develop_manipulation")
            check(not s.choose(1 if spec=="objects" else 0),"Escolha permanente")
        check(outcomes.size()==2,"Aprendizado cobre sucesso e orientação após fracasso")
    for category in State.Nen.CATEGORIES:
        var s=ready();s.nen["category"]=category;s.open_event("develop_manipulation")
        check((s.choice_reason(0)=="")==(category=="Manipulação"),"Categoria compatível exigida")
    var s=ready();s.nen["water_done"]=false;s.open_event("develop_manipulation")
    check(not s.choose(0),"Revelação necessária")
    s=ready();s.nen["mastery"]=1;s.open_event("develop_manipulation")
    check(not s.choose(1),"Fundamentos necessários")
    for spec in ["objects","motor"]:
        for enemy in ["bandit","fighter","candidate"]:
            s=battle(spec,enemy)
            var before: Dictionary=s.serialize().duplicate(true)
            var available: bool=spec=="motor" or enemy=="bandit"
            check((s.Battle.reason(s,"hatsu")=="")==available,"Alvo contextual correto")
            if not available:
                check(not s.Battle.act(s,"hatsu",1) and s.serialize()==before,"Sem alvo não consome turno, RNG ou Saúde")
                s=snapshot(s)
                check(s.Battle.reason(s,"hatsu")!="","Ausência de alvo persiste ao carregar")
    var stats: Dictionary={}
    for spec in ["objects","motor"]:
        var successes: int=0
        var failed: int=0
        for seed_value in range(100):
            s=battle(spec,"bandit",seed_value)
            var hp: int=s.battle["hp"]
            var test: Dictionary=s.Battle.test(s,"hatsu")
            check(test["attribute"]==("intellect" if spec=="objects" else "agility") and test["difficulty"]==(10 if spec=="objects" else 13),"Atributo e dificuldade reais")
            check(s.Battle.act(s,"hatsu",1),"Resolve comando")
            if s.result.contains("· sucesso"):
                successes+=1
                check(s.battle["opening"] and s.health==(8 if spec=="objects" else 9),"Abertura e redução limitada na resposta atual")
            else:
                failed+=1
                check(not s.battle["opening"] and s.health==7,"Falha permite resposta integral")
            check(s.battle["hp"]==hp,"Comando não causa dano nem vence sozinho")
            check(s.Battle.reason(s,"hatsu")!="" and s.Battle.reason(s,"ten")!="" and s.Battle.reason(s,"zetsu")!="","Cooldown de aura compartilhado")
            check(not s.Battle.act(s,"attack",1),"Token antigo não repete turno")
            if seed_value<5:
                var clone=snapshot(s)
                s.Battle.act(s,"attack",2);clone.Battle.act(clone,"attack",2)
                check(s.serialize()==clone.serialize(),"Próximo turno e RNG iguais após carregar")
                check(s.Battle.reason(s,"hatsu")=="" or not s.Battle.active(s),"Ação comum recupera uso")
                check(not s.battle["opening"],"Ataque consome abertura")
        check(successes>0 and failed>0,"Comando pode acertar ou falhar")
        var simulations: Dictionary={}
        for enemy in ["bandit","fighter"]:
            var wins: int=0
            var turns: int=0
            var longest: int=0
            for seed_value in range(100):
                s=battle(spec,enemy,seed_value)
                if enemy=="fighter":s.battle["intent"]="prepare"
                while s.Battle.active(s) and s.battle["turn"]<40:
                    s.Battle.act(s,"hatsu" if s.Battle.reason(s,"hatsu")=="" else "attack",s.battle["turn"])
                    check(s.health>=0 and s.health<=10,"Saúde limitada")
                check(not s.Battle.active(s),"Confronto não bloqueia")
                if s.battle["outcome"] in ["victory","enemy_yield"]:wins+=1
                turns+=s.battle["turn"];longest=maxi(longest,s.battle["turn"])
            simulations[enemy]={"wins":wins,"mean_turns":turns/100.0,"max_turns":longest}
        stats[spec]={"success":successes,"failure":failed,"battles":simulations}
        s=battle(spec,"bandit",4)
        while s.Battle.active(s) and s.battle["turn"]<40:
            s.Battle.act(s,"hatsu" if s.Battle.reason(s,"hatsu")=="" else "defend",s.battle["turn"])
        check(not s.Battle.active(s) and s.battle["outcome"]=="incapacity","Comando e defesa não criam bloqueio infinito")
    for pair in [["signal_roof","objects"],["reservoir","objects"],["exam_capture","objects"],["escort_checkpoint","motor"]]:
        var outcomes: Dictionary={}
        for seed_value in range(25):
            s=ready(pair[1],seed_value);s.open_event(pair[0])
            if pair[0]=="exam_capture":s.exam={"status":"active","sequence":["exam_crossing","exam_capture","exam_team","exam_duel"],"stage":2,"setbacks":0,"awarded":false}
            var index: int=s.demo["choices"].size()-1
            check(s.choice_reason(index)=="" and s.choose(index),"Aplicação narrativa contextual")
            outcomes[s.result.contains("· sucesso")]=true
            s=snapshot(s)
            if s.Battle.active(s):
                check(s.current_id=="escort_checkpoint","Fracasso da interrupção inicia confronto")
                s.Battle.act(s,"yield",1);check(s.advance() and s.current_id=="escort_done","Retirada continua sem entrega falsa")
        check(outcomes.size()==2,"Cena cobre sucesso e fracasso")
        s=ready("motor" if pair[1]=="objects" else "objects");s.open_event(pair[0])
        check(s.choice_reason(s.demo["choices"].size()-1)!="","Outra especialização não libera escolha")
    s=ready("objects");s.open_event("market");s=snapshot(s)
    check(s.nen["category"]=="Manipulação" and s.serialize()["version"]==9,"Save v9 permanece compatível")
    var invalid: Dictionary=s.serialize().duplicate(true)
    invalid["nen"]["category"]="Reforço"
    var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state(PATH)["error"]!="","Save incompatível rejeitado")
    s=battle("motor","bandit")
    invalid=s.serialize().duplicate(true);invalid["battle"]["enemy"]="fighter"
    f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state(PATH)["error"]!="","Confronto não previsto na escolha continua rejeitado")
    check(not s.Hatsu.valid({"id":"manipulation","specialization":"total","learned":true},s),"Comando ilimitado não existe")
    print("MANIPULAÇÃO 10D: %d verificações, %d falhas; simulações=%s" % [checks,failures,stats])
    DirAccess.remove_absolute(PATH)
    quit(1 if failures else 0)
