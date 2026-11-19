extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func setup(seed_value: int):
    var s=State.new();s.rng.seed=seed_value;s.start("Candidato");s.active_adventure=false;s.current_adventure="";s.open_event("exam_invite");return s
func run() -> void:
    var combinations: Dictionary={}
    var results: Dictionary={}
    for seed_value in range(300):
        var s=setup(seed_value)
        check(s.choose(1),"Entrada sem Nen ou nível")
        var sequence: Array=s.exam["sequence"].duplicate()
        combinations[JSON.stringify(sequence)]=true
        Store.save(s,"user://test_exam.json")
        var loaded=Store.load_state("user://test_exam.json")
        check(loaded["error"]=="" and loaded["state"].exam["sequence"]==sequence,"Sorteio preservado antes da chegada")
        s.advance();s.choose(0);s.advance();s.choose(0);s.advance()
        var steps: int=0
        while s.exam["status"]=="active" and s.health>0 and steps<30:
            if seed_value<16:
                Store.save(s,"user://test_exam.json")
                check(Store.load_state("user://test_exam.json")["error"]=="","Carrega cada ponto intermediário")
            if s.Battle.active(s):
                # Exibe julgamento e então rendição, conforme regra anunciada.
                if s.battle["turn"]==1:s.Battle.act(s,"defend",1)
                else:s.Battle.act(s,"yield",s.battle["turn"])
            else:
                var options: Array=[]
                for i in range(s.demo["choices"].size()):
                    if s.choice_reason(i)=="":options.append(i)
                if options.is_empty():check(false,"Sem bloqueios");break
                var index: int=0
                if s.current_id=="exam_judgment":index=0
                elif s.current_id=="exam_survival":index=0
                s.choose(index)
            if not s.Battle.active(s):s.advance()
            steps+=1
        check(steps<30 and s.exam["status"]!="active","Exame termina sem travar")
        check(s.exam["sequence"]==sequence,"Sem rerrolagem")
        if s.health>0 and s.current_id not in ["exam_pass","exam_fail","exam_withdraw"]:s.advance()
        if s.exam["status"]=="approved":
            check(s.Items.quantity(s,"hunter_license")==1 and s.exam["awarded"],"Aprovação concede licença única")
            var xp: int=s.xp
            s.Exam.on_open(s)
            check(s.xp==xp and s.Items.quantity(s,"hunter_license")==1,"Sem prêmio duplicado")
            check(s.catalog.eligible(s.catalog.events["licensed_contract"]["conditions"],s),"Oportunidade exclusiva liberada")
        else:check(s.Items.quantity(s,"hunter_license")==0,"Sem licença após reprovação")
        Store.save(s,"user://test_exam.json")
        loaded=Store.load_state("user://test_exam.json")
        check(loaded["error"]=="","Estado final carrega")
        results[s.exam["status"]]=int(results.get(s.exam["status"],0))+1
    check(combinations.size()==16,"Todas as 16 combinações")
    var s=setup(1);s.choose(2);s.advance()
    check(s.exam["status"]=="unentered" and not s.active_adventure,"Adiar mantém jornada")
    s=setup(2);s.choose(1);s.advance();s.choose(1);s.advance()
    check(s.exam["status"]=="withdrawn" and s.current_id=="exam_withdraw","Desistência retorna sem final de jornada")
    check(not s.choose(99),"Escolha inválida não altera estado")
    var old: Dictionary={}
    # Fixture v8 coerente sem eventos novos.
    s=State.new();s.start("Anterior");s.open_event("market");old=s.serialize().duplicate(true);old["version"]=8;old.erase("exam")
    var f=FileAccess.open("user://test_exam.json",FileAccess.WRITE);f.store_string(JSON.stringify(old));f.close()
    var migrated=Store.load_state("user://test_exam.json")
    check(migrated["error"]=="" and migrated["state"].exam["status"]=="unentered","Migração v8 sem participação retroativa")
    s=setup(45);s.choose(1);s.advance();s.choose(0);s.advance();s.choose(0);s.advance()
    Store.save(s,"user://test_exam.json")
    var middle=Store.load_state("user://test_exam.json")
    check(middle["error"]=="" and middle["state"].serialize()==s.serialize(),"Save em prova preserva estado e RNG")
    s.exam["stage"]=4;s.exam["sequence"][3]="exam_duel";s.open_event("exam_duel");s.choose(0)
    Store.save(s,"user://test_exam.json")
    var combat=Store.load_state("user://test_exam.json")
    check(combat["error"]=="","Save no duelo final")
    var other=combat["state"]
    s.Battle.act(s,"defend",1);other.Battle.act(other,"defend",1)
    check(s.serialize()==other.serialize(),"Duelo retoma sem rerrolar")
    s.Battle.act(s,"yield",s.battle["turn"]);s.advance()
    check(s.exam["status"]=="approved" and s.Items.quantity(s,"hunter_license")==1,"Julgamento e cooperação permitem rendição avaliada")
    var invalid: Dictionary=s.serialize().duplicate(true);invalid["exam"]["status"]="failed"
    f=FileAccess.open("user://test_exam.json",FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state("user://test_exam.json")["error"]!="","Licença sem aprovação recusada")
    invalid=s.serialize().duplicate(true);invalid["exam"]["stage"]=1;invalid["current"]="exam_duel";invalid["choice"]=-1;invalid["next"]="";invalid["result"]=""
    f=FileAccess.open("user://test_exam.json",FileAccess.WRITE);f.store_string(JSON.stringify(invalid));f.close()
    check(Store.load_state("user://test_exam.json")["error"]!="","Prova ativa após fim recusada")
    check(not s.Items.operate(s,"hunter_license","use",s.inventory["revision"]) and not s.Items.operate(s,"hunter_license","equip",s.inventory["revision"]),"Licença não é consumível nem equipamento")
    for pair in [["exam_crossing","nen_ten"],["exam_capture","nen_zetsu"],["exam_team","nen_ren"]]:
        s=setup(4);s.choose(1);s.exam["stage"]=1;s.open_event(pair[0])
        var index: int=-1
        for i in range(s.demo["choices"].size()):
            if s.demo["choices"][i].get("conditions",{}).get("flags",{}).get(pair[1],false):index=i
        check(index>=0 and s.choice_reason(index)!="","Nen bloqueado sem técnica")
        s.flags[pair[1]]=true
        check(s.choice_reason(index)=="","Técnica aprendida abre alternativa")
    for pair in [["exam_capture","emission","precision"],["exam_team","reinforce","power"]]:
        s=setup(4);s.choose(1);s.open_event(pair[0])
        var index: int=-1
        for i in range(s.demo["choices"].size()):
            if s.demo["choices"][i].get("conditions",{}).has("hatsu"):index=i
        check(index>=0 and s.choice_reason(index)!="","Hatsu ausente bloqueado")
        s.hatsu={"learned":true,"id":pair[1],"specialization":pair[2]}
        check(s.choice_reason(index)=="","Especialização correta abre alternativa")
    s=setup(8);s.choose(1);s.exam["stage"]=3;s.open_event("exam_survival")
    s.Items.apply(s,{"items_add":{"bandage":1}})
    check(s.choose(2) and s.Items.quantity(s,"bandage")==0 and s.flags.get("exam_helped",false),"Ajuda consome bandagem e altera cooperação")
    s=setup(9);s.choose(1);s.exam["stage"]=4;s.exam["sequence"][3]="exam_duel";s.open_event("exam_duel");s.choose(0);s.health=1
    while s.Battle.active(s):s.Battle.act(s,"defend",s.battle["turn"])
    Store.save(s,"user://test_exam.json")
    check(s.exam["status"]=="failed" and s.health==0 and Store.load_state("user://test_exam.json")["error"]=="","Incapacidade no exame persiste sem licença")
    s=setup(23);s.choose(1);s.advance();s.choose(0);s.advance();s.choose(0);s.advance()
    s.choose(0);s.advance();s.choose(0)
    Store.save(s,"user://test_exam.json")
    check(Store.load_state("user://test_exam.json")["error"]=="","Save após decidir continuar no intervalo")
    var journeys: Dictionary={}
    for participate in [false,true]:
        var group: Dictionary={}
        for seed_value in range(50):
            if participate:s=setup(seed_value);s.choose(1);s.advance()
            else:
                s=State.new();s.rng.seed=seed_value;s.start("Outra trajetória");s.flags["exam_ignored"]=true
                if s.current_id=="exam_invite":s.choose(3);s.advance()
            var steps: int=0
            while s.health>0 and s.demo["kind"]!="ending" and steps<150:
                if s.Battle.active(s):
                    preload("res://tests/battle_driver.gd").resolve(s)
                else:
                    var options: Array=[]
                    for i in range(s.demo["choices"].size()):
                        if s.choice_reason(i)=="":options.append(i)
                    if options.is_empty():check(false,"Jornada sem saída");break
                    s.choose(options[s.rng.randi_range(0,options.size()-1)])
                if not s.Battle.active(s):s.advance()
                steps+=1
            check(steps<150 and (s.health==0 or s.demo["kind"]=="ending"),"Jornada completa com/sem exame")
            if not participate:check(s.exam["status"]=="unentered" and s.Items.quantity(s,"hunter_license")==0,"Exame continua opcional")
            group[s.exam["status"]]=int(group.get(s.exam["status"],0))+1
        journeys["com_exame" if participate else "sem_exame"]=group
    print("JORNADAS EXAME: ",journeys)
    print("EXAME: %d verificações, %d falhas; combinações=%d, resultados=%s" % [checks,failures,combinations.size(),results])
    DirAccess.remove_absolute("user://test_exam.json")
    quit(1 if failures else 0)
