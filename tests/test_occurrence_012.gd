extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const PATH="user://test_occurrence_012.json"
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,text: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(text)
func fresh(seed_value: int=777):
    var s=State.new();s.rng.seed=seed_value;s.start("Candidatura");s.open_event("market");return s
func snapshot(s):
    check(Store.save(s,PATH)=="","Salva histórico e pendências")
    var loaded=Store.load_state(PATH,false)
    check(loaded.error=="","Carrega histórico: "+loaded.error)
    if loaded.error!="":return s
    check(s.serialize()==loaded.state.serialize(),"Estado, visitas, tentativas, provas e RNG idênticos")
    check(s.demo==loaded.state.demo,"Textos contextuais da tentativa preservados ao carregar")
    return loaded.state
func experiences(s) -> void:
    var gained=0
    for id in ["012_inn","012_markers","012_mooring","012_window","012_mending","012_observation","012_scales","012_receipt"]:
        if id in s.seen:continue
        s.open_event(id);check(s.choose(0 if id=="012_receipt" else 2),"Experiência distinta fora do exame")
        gained+=1
        if gained<6:check(not s.Exam.can_start(s),"Intervalo não pode ser ignorado")
        if gained==6:break
    check(gained==6,"Seis experiências disponíveis")
func run() -> void:
    for id in ["dock","tournament","nen_offer","012_window"]:
        var s=fresh();s.open_event(id)
        check(not s.catalog.available(id,s),"Visto não volta ao sorteio: "+id)
        check(s.choose(1),"Resolve acontecimento comum")
        s=snapshot(s)
        var before=s.serialize().duplicate(true);s.open_event(id)
        check(s.serialize()==before,"Não reabre acontecimento comum resolvido")
        check(not s.catalog.available(id,s),"Carregar não apaga ocorrência")
    var picker=fresh();picker.active_adventure=false;picker.current_adventure=""
    var chosen={};var exhausted=false
    for i in range(200):
        var id: String=picker.catalog.select(picker)
        if id=="crossroads":exhausted=true;break
        check(not chosen.has(id),"Sorteio global não repete IDs comuns")
        chosen[id]=true;picker.seen.append(id);picker.visits[id]=1;picker.step+=1;picker.last_visit[id]=picker.step
    check(exhausted,"Catálogo reduzido termina com decisão natural, sem loop")
    for i in range(5):check(picker.catalog.select(picker)=="crossroads","Esgotamento não força repetição")
    var legacy=fresh();legacy.visits[legacy.current_id]=3
    legacy=snapshot(legacy);check(legacy.visits[legacy.current_id]==3 and not legacy.catalog.available(legacy.current_id,legacy),"Saves antigos preservam visitas históricas sem permitir novas repetições")
    var mission=fresh();mission.open_event("c_missing_offer")
    for index in [0,1,2,1]:
        check(mission.choose(index),"Escolha da missão encadeada");check(mission.advance(),"Continuação obrigatória preservada")
        mission=snapshot(mission)
    check(mission.current_id=="c_missing_done" and mission.missions.c_missing=="completed","Cenas distintas não são confundidas com repetição")
    var s=fresh(917);s.open_event("exam_invite");check(s.choose(1),"Primeira inscrição sem Nen")
    s.advance();s.choose(0)
    s.flags.exam_helped=true
    s.Exam.conclude(s,"failed");s.advance();s.choose(0)
    check(s.exam.status=="failed" and s.serialize().exam_history.size()==1,"Reprovação arquivada uma única vez")
    s=snapshot(s)
    check(not s.Exam.can_start(s) and not s.catalog.available("exam_invite",s),"Sem reinscrição imediata")
    experiences(s)
    check(s.Exam.can_offer(s) and s.catalog.available("exam_invite",s),"Exame é a exceção após experiências novas")
    var healthy=s.health;s.health=4;check(not s.Exam.can_start(s),"Recuperação é requisito da nova viagem");s.health=maxi(healthy,5)
    var seen_before=s.seen.duplicate();var old_sequence=s.exam.sequence.duplicate()
    s.open_event("exam_invite");s=snapshot(s)
    var twin=snapshot(s)
    check(s.choose(1) and twin.choose(1),"Reinscrição após reprovação")
    check(s.serialize()==twin.serialize(),"Mesmo sorteio da nova seleção ao continuar de um save")
    check(s.exam.status=="active" and s.serialize().exam_history.size()==2,"Nova tentativa independente")
    check(not s.flags.get("exam_helped",false) and s.exam_history[0].flags.get("exam_helped",false),"Cooperação anterior arquivada, sem benefício duplicado")
    check(s.exam_history[0].sequence==old_sequence,"Provas anteriores conservadas")
    for id in seen_before:check(id in s.seen,"A tentativa não reinicia o histórico mundial")
    s=snapshot(s);s.advance();check(s.current_id=="exam_arrival","Reentrada nas provas encadeadas")
    for attribute in s.attributes:s.attributes[attribute]=10
    var steps=0
    while s.exam.status=="active" and steps<35:
        steps+=1
        if s.Battle.active(s):s.Battle.act(s,"attack",s.battle.turn)
        else:
            var selected=-1
            for i in range(s.demo.choices.size()):
                if s.choice_reason(i)=="":selected=i;break
            check(selected>=0 and s.choose(selected),"Escolha válida na segunda seleção")
        if not s.Battle.active(s):s.advance()
        if steps==3:s=snapshot(s)
    check(steps<35 and s.exam.status=="approved","Aprovação alcançável na segunda tentativa")
    check(s.Items.quantity(s,"hunter_license")==1,"Licença única")
    s=snapshot(s)
    check(not s.Exam.can_offer(s) and not s.Exam.can_start(s) and not s.catalog.available("exam_invite",s),"Aprovado não repete o exame")
    var final=s.serialize().duplicate(true);s.open_event("exam_invite");check(s.serialize()==final,"Lógica bloqueia reinscrição após aprovação")
    var old=fresh();old.open_event("exam_invite");old.choose(1);old.advance();old.choose(0);old.Exam.conclude(old,"failed");old.advance();old.choose(0)
    var old_payload=old.serialize();old_payload.erase("exam_history")
    FileAccess.open(PATH,FileAccess.WRITE).store_string(JSON.stringify(old_payload))
    var migrated=Store.load_state(PATH,false)
    check(migrated.error=="" and migrated.state.serialize().exam_history.size()==1,"Migra save v10 anterior com reprovação conhecida")
    check(migrated.error=="" and migrated.state.records==old.records and migrated.state.rng.state==old.rng.state,"Migração não inventa recompensas ou rolagens")
    DirAccess.remove_absolute(PATH)
    print("OCORRÊNCIAS 012: %d verificações, %d falhas; %d oportunidades únicas antes do esgotamento" % [checks,failures,chosen.size()])
    quit(1 if failures else 0)
