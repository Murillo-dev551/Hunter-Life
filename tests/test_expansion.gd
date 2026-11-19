extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const Driver=preload("res://tests/battle_driver.gd")
const PATH="user://test_expansion.json"
var checks: int=0
var failures: int=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func fresh(seed_value: int=0):
    var s=State.new();s.rng.seed=seed_value;s.start("Viajante");s.battle={};s.active_adventure=false;s.current_adventure="";return s
func snapshot(s):
    check(Store.save(s,PATH)=="","Salva estado intermediário")
    var loaded=Store.load_state(PATH)
    check(loaded["error"]=="","Carrega aventura nova")
    if loaded["error"]!="":return s
    check(loaded["state"].serialize()==s.serialize(),"RNG, histórico, progresso e flags preservados")
    return loaded["state"]
func pick(s,index: int) -> void:
    check(s.choose(index),"Escolha elegível: "+s.current_id)
    var before: Dictionary=s.serialize().duplicate(true)
    check(not s.choose(index) and before==s.serialize(),"Não repete recompensa")
    s.advance()
func complete_safe(s,adventure: String) -> void:
    s.open_event(adventure+"_offer")
    if adventure=="escort":
        for index in [0,3,3,1,1]:pick(s,index)
    else:
        for index in [0,3,3,2,1]:pick(s,index)
    check(s.demo["kind"]=="adventure_end" and not s.active_adventure,"Conclusão devolve autonomia")
    snapshot(s)
func run() -> void:
    var s=fresh()
    check(s.error=="" and s.catalog.events.size()==92,"81 eventos válidos")
    for order in [["escort","ruins"],["ruins","escort"]]:
        s=fresh()
        for adventure in order:
            complete_safe(s,adventure)
            check(adventure in s.completed,"Registra conclusão: "+adventure)
            pick(s,0)
        check("escort" in s.completed and "ruins" in s.completed and s.health==10,"Duas aventuras sem Nen, itens ou combate")
    for enemy_result in ["victory","enemy_yield","fled","yielded","incapacity"]:
        s=fresh();s.open_event("escort_checkpoint");s.choose(3)
        s=snapshot(s)
        if enemy_result=="victory":s.battle["hp"]=0
        if enemy_result=="incapacity":s.health=0
        s.Battle.finish(s,enemy_result)
        var before: Dictionary=s.serialize().duplicate(true)
        s.Battle.finish(s,enemy_result)
        check(before==s.serialize(),"Resultado de batalha idempotente")
        s=snapshot(s)
        if enemy_result=="incapacity":check(not s.advance() and s.pending_next=="","Incapacidade encerra sem continuação")
        else:
            check(s.advance(),"Retoma narrativa após confronto")
            check(s.current_id==("escort_account" if enemy_result in ["victory","enemy_yield"] else "escort_done"),"Rota depende do resultado do combate")
    s=fresh();s.jenny=0;s.open_event("escort_road")
    check(s.choice_reason(3)!="" and s.choice_reason(0)=="","Sem dinheiro há alternativa")
    check(s.choice_reason(1)!="","Rota depende da preparação")
    s.flags["escort_route"]=true
    check(s.choice_reason(1)=="","Planejamento libera desvio")
    s.open_event("ruins_team")
    check(s.choice_reason(1)!="" and s.choice_reason(2)!="","Equipamento necessário para alternativas específicas")
    s.Items.apply(s,{"items_add":{"lantern":1,"rope":1}})
    check(s.choice_reason(1)=="" and s.choice_reason(2)=="","Ferramentas existentes habilitam preparação")
    s.open_event("ruins_entry")
    check(s.choice_reason(4)!="","Ten ausente não disponível")
    for technique in ["ten","zetsu","ren"]:s.Nen.apply(s,{"nen_learn":technique})
    check(s.choice_reason(4)=="","Ten aprendido abre travessia")
    s.open_event("escort_checkpoint")
    check(s.choice_reason(4)=="","Ren aprendido abre negociação")
    s.open_event("ruins_archive")
    check(s.choice_reason(3)!="","Precisão não é concedida por atributo")
    s.nen["category"]="Emissão";s.nen["water_done"]=true;s.hatsu={"id":"emission","specialization":"precision","learned":true}
    check(s.choice_reason(3)=="","Especialização correta libera a trava")
    s.hatsu["specialization"]="power"
    check(s.choice_reason(3)!="","Outra especialização não libera Precisão")
    s.open_event("reservoir")
    check(s.choice_reason(1)!="","Emissão não substitui Reforço")
    s.nen["category"]="Reforço";s.hatsu={"id":"reinforce","specialization":"power","learned":true}
    check(s.choice_reason(1)=="","Potência física habilita esforço específico")
    s=snapshot(s)
    check(s.hatsu["specialization"]=="power" and s.nen["category"]=="Reforço","Categoria e especialização persistem")
    s=fresh();s.open_event("escort_checkpoint");s.choose(3);s.Battle.act(s,"defend",1)
    var clone=snapshot(s)
    s.Battle.act(s,"attack",s.battle["turn"]);clone.Battle.act(clone,"attack",clone.battle["turn"])
    check(s.serialize()==clone.serialize(),"Carregar no meio do confronto preserva próximo turno e RNG")
    s=fresh();s.open_event("ruins_offer")
    for index in [0,3,3,2,2]:pick(s,index)
    check(s.flags.get("ruins_stolen",false) and s.catalog.eligible(s.catalog.events["false_account"]["conditions"],s),"Ocultação gera consequência persistente")
    s=snapshot(s)
    var accessible: int=0
    for id in s.catalog.events.keys().slice(58,78):
        var probe=fresh()
        probe.flags={"escort_completed":true,"ruins_shared":true,"dishonest":true}
        check(probe.catalog.eligible(probe.catalog.events[id]["conditions"],probe),"Contexto viável para novo acontecimento: "+id)
        accessible+=1
    check(accessible==20,"Vinte acontecimentos novos possuem contexto elegível")
    s=fresh()
    for pair in [["escort_return","escort_completed"],["ruins_return","ruins_shared"],["false_account","dishonest"]]:
        var event=s.catalog.events[pair[0]]
        check(not s.catalog.eligible(event["conditions"],s),"Retorno exige passado real")
        s.flags[pair[1]]=true
        check(s.catalog.eligible(event["conditions"],s),"Decisão anterior abre retorno")
    # Fixture v9 anterior, apenas IDs do catálogo 10A e inventário vazio.
    s=fresh();s.seen=[];s.visits={};s.last_visit={};s.step=0
    s.open_event("market");s.choose(0);s=snapshot(s)
    check(not s.flags.has("escort_completed") and s.serialize()["version"]==9,"Save antigo não recebe consequências retroativas")
    var samples: Dictionary={}
    for seed_value in range(500):
        s=fresh(seed_value);s.flags={};s.visits={};s.last_visit={}
        var id: String=s.catalog.select(s)
        samples[id]=int(samples.get(id,0))+1
    check(samples.has("escort_offer") and samples.has("ruins_offer") and samples.has("exam_invite") and samples.has("offer"),"Novas e antigas oportunidades coexistem")
    var results: Dictionary={}
    for adventure in ["escort","ruins"]:
        var group: Dictionary={}
        for seed_value in range(100):
            s=fresh(seed_value);s.open_event(adventure+"_offer");s.choose(0);s.advance()
            var steps: int=0
            while s.active_adventure and s.health>0 and steps<20:
                s=snapshot(s)
                if s.Battle.active(s):Driver.resolve(s)
                else:
                    var options: Array=[]
                    for i in range(s.demo["choices"].size()):
                        if s.choice_reason(i)=="":options.append(i)
                    check(not options.is_empty(),"Aventura sem bloqueio")
                    if options.is_empty():break
                    s.choose(options[s.rng.randi_range(0,options.size()-1)])
                if not s.Battle.active(s):s.advance()
                steps+=1
            check(steps<20 and (not s.active_adventure or s.health==0),"Aventura termina sem bloqueio")
            var result: String="completed" if adventure in s.completed else "incapacity" if s.health==0 else "withdrawn"
            group[result]=int(group.get(result,0))+1
        results[adventure]=group
    var endings: Dictionary={}
    var reached: Dictionary={}
    for seed_value in range(100):
        s=fresh(seed_value)
        var steps: int=0
        while s.health>0 and s.demo["kind"]!="ending" and steps<180:
            reached[s.current_id]=true
            if s.Battle.active(s):Driver.resolve(s)
            else:
                var options: Array=[]
                for i in range(s.demo["choices"].size()):
                    if s.choice_reason(i)=="":options.append(i)
                check(not options.is_empty(),"Jornada tem saída")
                if options.is_empty():break
                s.choose(options[s.rng.randi_range(0,options.size()-1)])
            if not s.Battle.active(s):s.advance()
            steps+=1
        check(steps<180 and (s.health==0 or s.demo["kind"]=="ending"),"Jornada completa")
        endings[s.current_id]=int(endings.get(s.current_id,0))+1
    print("EXPANSÃO 10B: %d verificações, %d falhas; aventuras=%s; seleção=%s; jornadas=%s; eventos alcançados=%d" % [checks,failures,results,samples,endings,reached.size()])
    DirAccess.remove_absolute(PATH)
    quit(1 if failures else 0)
