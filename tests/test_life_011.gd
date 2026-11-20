extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const PATH="user://test_life_011.json"
var checks=0
var failures=0
var visited: Dictionary={}
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(message)
func fresh(seed_value: int=42,licensed: bool=false):
    var s=State.new();s.rng.seed=seed_value;s.start("Vida de Hunter");s.open_event("market")
    if licensed:
        s.exam={"status":"approved","sequence":[s.Exam.OPTIONS[0][0],s.Exam.OPTIONS[1][0],s.Exam.OPTIONS[2][0],s.Exam.OPTIONS[3][0]],"stage":4,"setbacks":0,"awarded":true}
        s.Items.apply(s,{"items_add":{"hunter_license":1}})
    return s
func snapshot(s):
    check(Store.save(s,PATH)=="","Salva estado de missão")
    var loaded=Store.load_state(PATH,false)
    check(loaded.error=="","Carrega missão: "+loaded.error)
    if loaded.error!="":return s
    check(s.serialize()==loaded.state.serialize(),"Missão, gênero, recursos e RNG preservados")
    return loaded.state
func run() -> void:
    var reference=fresh()
    check(reference.error=="" and reference.catalog.events.size()==182,"Catálogo completo com 182 acontecimentos")
    check(reference.catalog.mission_entries.size()==10,"Dez missões novas como unidades")
    var counts={"hunter":0,"common":0}
    var edges={}
    for id in reference.catalog.events:
        var event: Dictionary=reference.catalog.events[id]
        if event.has("mission"):counts[event.mission_category]+=1
        check(event.paragraphs.size()>=1 and not event.title.is_empty(),"Contexto narrativo presente")
        edges[id]=[]
        for choice in event.choices:
            check(not choice.result.is_empty(),"Consequência escrita")
            for effect in [choice,choice.get("failure",{})]:
                if effect.has("next"):check(reference.catalog.events.has(effect.next),"Referência existente");edges[id].append(effect.next)
        for reward in event.get("battle_rewards",{}).values():
            if reward.has("next"):check(reference.catalog.events.has(reward.next),"Continuação de combate existente");edges[id].append(reward.next)
    check(counts=={"hunter":35,"common":35},"Distribuição das setenta cenas de missão")
    for mission_id in reference.catalog.mission_entries:
        var entry=reference.catalog.mission_entries[mission_id]
        var reachable={entry:true};var queue=[entry]
        while not queue.is_empty():
            for target in edges[queue.pop_front()]:
                if not reachable.has(target):reachable[target]=true;queue.append(target)
        check(reachable.size()==7,"Sete cenas alcançáveis por missão: "+mission_id)
        check(reference.catalog.events[mission_id+"_done"].mission_outcome=="completed" and reference.catalog.events[mission_id+"_failed"].mission_outcome=="failed","Desfechos distintos")
        var unlicensed=fresh();var licensed=fresh(91,true)
        var event=reference.catalog.events[entry]
        if event.mission_category=="hunter":
            check(not unlicensed.catalog.eligible(event.conditions,unlicensed),"Sem licença não recebe missão Hunter")
            var previous=unlicensed.current_id;unlicensed.open_event(entry);check(unlicensed.current_id==previous,"Lógica impede acesso direto sem licença")
        check(licensed.catalog.eligible(event.conditions,licensed),"Licença permite oportunidade sem Nen")
    for gender in ["unspecified","male","female"]:
        var s=State.new();s.rng.seed=167;s.start("Pessoa",0,gender)
        var comparison=State.new();comparison.rng.seed=167;comparison.start("Pessoa",0,"unspecified")
        check(s.attributes==comparison.attributes and s.nen==comparison.nen and s.rng.state==comparison.rng.state,"Gênero não altera capacidades ou sorteios")
        s.open_event("011_hearing");check(s.demo.paragraphs[1].contains({"male":"senhor","female":"senhora","unspecified":"viajante"}[gender]),"Tratamento narrativo apropriado")
        snapshot(s)
    for id in ["011_capture_follow","011_fair_follow","011_fair_reckoning","011_market_reckoning"]:
        var s=fresh(777,true);var conditions: Dictionary=s.catalog.events[id].conditions
        check(not s.catalog.eligible(conditions,s),"Consequência depende de decisão anterior")
        for key in conditions.get("flags",{}):s.flags[key]=conditions.flags[key]
        check(s.catalog.eligible(conditions,s),"Consequência persistente alcançável: "+id)
    check(reference.catalog.events.dock.choices[1].failure.health==-1,"Fracasso no cais pode ferir")
    check(reference.catalog.events.cart.choices[1].failure.jenny==-8,"Improviso mal executado tem custo")
    check(reference.catalog.events.market.choices[0].failure.flags.merchant_mistake,"Erro no depósito abre consequência futura")
    for event in reference.catalog.events.values():
        for choice in event.choices:
            var next: String=choice.get("next","")
            if next!="" and reference.catalog.events[next].kind=="ending":
                check(not choice.label.to_lower().contains("final") and not choice.label.to_lower().contains("encerrar"),"Decisão natural antecede o nome do final")
    var outcomes={};var examples={}
    for mission_id in reference.catalog.mission_entries:
        outcomes[mission_id]={}
        for seed_value in range(50):
            var s=fresh(500+seed_value,true)
            if s.missions.has(mission_id):continue
            if seed_value%2==0:s.Items.apply(s,{"items_add":{"rope":1,"map":1,"lantern":1}})
            s.open_event(reference.catalog.mission_entries[mission_id]);visited[s.current_id]=true
            check(s.missions.get(mission_id)=="offered","Oferta registrada")
            if seed_value==0:
                check(s.choose(1) and s.missions[mission_id]=="abandoned","Recusa encerra participação")
            else:
                check(s.choose(0),"Aceita missão");s.advance()
                var steps=0
                while s.missions.get(mission_id,"") in ["active","offered"] and s.health>0 and steps<14:
                    visited[s.current_id]=true;steps+=1
                    if s.Battle.active(s):
                        s.Battle.act(s,"flee" if seed_value%4==0 else "attack",s.battle.turn)
                        if not s.Battle.active(s) and s.health>0:s.advance()
                        continue
                    var candidates=[]
                    for i in range(s.demo.choices.size()):
                        if s.choice_reason(i)=="" and not s.demo.choices[i].has("mission_end"):candidates.append(i)
                    check(not candidates.is_empty(),"Sem caminho morto: "+s.current_id)
                    if candidates.is_empty():break
                    var index=int(candidates[(seed_value+steps)%candidates.size()])
                    s.choose(index)
                    if s.health>0:s.advance()
                    if steps==2:s=snapshot(s)
                check(steps<14,"Missão termina sem ciclo")
            visited[s.current_id]=true
            var status: String=s.missions.get(mission_id,"")
            outcomes[mission_id][status]=int(outcomes[mission_id].get(status,0))+1
            check(status in ["completed","failed","abandoned"],"Estado terminal da missão")
            check(not s.catalog.available(reference.catalog.mission_entries[mission_id],s),"Missão inteira não reaparece")
            if s.demo.kind=="adventure_end" and s.health>0:
                s.choose(0)
                check(s.demo.kind!="ending","Fim da missão não encerra a vida")
            var previous=s.serialize().duplicate(true)
            s.open_event(reference.catalog.mission_entries[mission_id]);check(s.serialize()==previous,"Bloqueia reinício e ramos alternativos")
            s=snapshot(s)
            if seed_value==1:examples[mission_id]={"outcome":status,"health":s.health,"level":s.level,"jenny":s.jenny}
        check(outcomes[mission_id].has("completed") and outcomes[mission_id].has("failed") and outcomes[mission_id].has("abandoned"),"Conclusão, fracasso e abandono exercitados: "+mission_id)
    var consequence=fresh(777,true);consequence.open_event("c_fair_offer")
    for index in [0,0,2,1,2]:
        check(consequence.choose(index),"Caminho comercial até a venda duplicada")
        check(consequence.advance(),"Continuação da cobrança comercial")
    check(consequence.current_id=="c_fair_failed" and consequence.flags.get("fair_double_sold",false),"Venda duplicada fracassa e deixa consequência")
    consequence.choose(0);consequence=snapshot(consequence)
    check(consequence.catalog.eligible(consequence.catalog.events["011_fair_reckoning"].conditions,consequence),"Cobrança real permanece elegível após carregar")
    consequence.open_event("011_fair_reckoning");var money=consequence.jenny
    check(consequence.choose(0) and consequence.jenny==money-45 and consequence.flags.get("fair_repaid",false),"Ressarcimento tem custo e estado persistente")
    consequence=snapshot(consequence);money=consequence.jenny
    check(not consequence.choose(0) and consequence.jenny==money,"Não duplica cobrança após carregar")
    var market_followed=false
    for seed_value in range(30):
        var s=fresh(777);s.rng.seed=seed_value;s.choose(0)
        if s.flags.get("merchant_mistake",false):
            s=snapshot(s);s.open_event("011_market_reckoning")
            check(s.catalog.eligible(s.demo.conditions,s) and s.choose(0),"Erro real no depósito permite acertar a conta posteriormente")
            market_followed=true;break
    check(market_followed,"Consequência do depósito exercitada desde a origem")
    var new_life=fresh();check(new_life.missions.is_empty() or new_life.missions.values().all(func(v):return v=="abandoned"),"Nova vida não herda missões")
    var death_seen=false
    for seed_value in range(20):
        var s=fresh(2000+seed_value,true);s.open_event("h_relic_offer");s.choose(0);s.advance();s.choose(1);s.advance()
        if s.current_id!="h_relic_trial":continue
        s.rng.seed=seed_value;s.choose(2)
        if s.flags.get("journey_deceased",false):
            death_seen=true;check(s.health==0 and not s.advance() and not s.result.contains("sem morte automática"),"Morte contextual interrompe a vida sem contradizer o texto")
            snapshot(s);break
    check(death_seen,"Fracasso extremamente perigoso verificado")
    var old=fresh();var old_data=old.serialize().duplicate(true);old_data.version=9;old_data.erase("gender");old_data.erase("missions")
    FileAccess.open(PATH,FileAccess.WRITE).store_string(JSON.stringify(old_data));var migrated=Store.load_state(PATH,false)
    check(migrated.error=="" and migrated.state.gender=="unspecified","v9 recebe gênero neutro sem perder dados")
    if migrated.error=="":check(migrated.state.rng.state==old.rng.state and migrated.state.jenny==old.jenny,"Migração não aplica recompensas ou sorteios")
    var end=fresh();end.open_event("crossroads")
    for choice in end.demo.choices:check(not choice.label.to_lower().contains("final") and not choice.label.to_lower().contains("encerrar"),"Decisões de vida naturais")
    end.choose(0);end.advance();check(end.demo.kind=="ending" and not end.advance(),"Vida estabelecida termina a jornada após a decisão")
    print("VIDA DE HUNTER 011: %d verificações, %d falhas; distribuição=%s; exemplos=%s; cenas visitadas=%d" % [checks,failures,outcomes,examples,visited.size()])
    FileAccess.open("res://tests/011_mission_results.json",FileAccess.WRITE).store_string(JSON.stringify({"outcomes":outcomes,"examples":examples,"visited":visited.keys()},"  "))
    DirAccess.remove_absolute(PATH);quit(1 if failures else 0)
