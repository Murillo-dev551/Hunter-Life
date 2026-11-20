extends SceneTree
const State=preload("res://scripts/game_state.gd")
const Store=preload("res://scripts/storage.gd")
const Art=preload("res://scripts/scenery.gd")
const UI=preload("res://scripts/ui/styles.gd")
const PATH="user://test_identity_012.json"
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func contrast(a: Color,b: Color) -> float:
    var x=a.srgb_to_linear();var y=b.srgb_to_linear()
    var l1=x.r*0.2126+x.g*0.7152+x.b*0.0722
    var l2=y.r*0.2126+y.g*0.7152+y.b*0.0722
    return (maxf(l1,l2)+0.05)/(minf(l1,l2)+0.05)
func run() -> void:
    check(UI.BODY.font_weight==400,"Texto usa face Regular, sem depender de fontes do sistema")
    check(contrast(UI.INK,UI.PANEL)>=7.0,"Contraste do texto narrativo")
    check(contrast(UI.MUTED,UI.BG)>=4.5,"Contraste das informações secundárias")
    check(contrast(UI.GOLD,UI.BG)>=4.5,"Dourado de recompensas continua legível sobre papel")
    check(contrast(UI.BG,UI.NAVY)>=7.0 and contrast(UI.BG,UI.ALERT)>=4.5,"Navegação legível em ambos os estados")
    var s=State.new();s.rng.seed=777;s.start("Diário")
    check(s.error=="" and s.catalog.events.size()==182,"Catálogo completo")
    var original=[];var illustrated=0
    for event in s.catalog.events.values():
        if original.size()<174:
            var clean=event.duplicate(true);clean.erase("folio");clean.erase("scenery");original.append(clean)
        if event.has("scenery"):
            illustrated+=1;check(Art.valid(event.scenery),"Cenário cadastrado")
        for choice in event.choices:
            for effect in [choice,choice.get("failure",{})]:
                if effect.get("next","")!="":
                    var next=s.catalog.events[effect.next]
                    check(not (event.has("scenery") and next.get("scenery","")==event.scenery),"Sem repetir a mesma arte em continuação consecutiva")
    check(JSON.stringify(original).sha256_text()==FileAccess.get_file_as_string("res://tests/fixtures/v011/catalog.sha256"),"Todos os textos, condições, pesos e consequências da v0.1.1 preservados")
    check(illustrated==16 and illustrated<float(s.catalog.events.size())*0.2,"Ilustrações explícitas e ocasionais")
    check(Art.data().size()==8,"Oito cenários consistentes")
    for id in Art.data():
        var path: String=Art.data()[id].path
        check(ResourceLoader.exists(path,"Texture2D"),"Arte local importada: "+id)
        check(not ResourceLoader.has_cached(path),"Catálogo não pré-carrega texturas: "+id)
    check(Art.texture("unknown")==null,"Fallback sem imagem para referência não cadastrada")
    var new_events: Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters_012.json"))
    var success=0;var failure=0
    for event in new_events:
        check(event.choices.size()>=2 and event.paragraphs.size()>=2,"Contexto e escolhas completos")
        for index in range(event.choices.size()):
            for seed_value in range(8):
                var actor=State.new();actor.rng.seed=777;actor.start("Diário");actor.open_event(event.id);actor.rng.seed=seed_value
                var required: Dictionary=event.choices[index].get("conditions",{}).get("items",{})
                if not required.is_empty():
                    check(actor.choice_reason(index)!="","Ferramenta ausente bloqueia só a alternativa correspondente")
                    actor.Items.apply(actor,{"items_add":required})
                var before=actor.serialize().duplicate(true)
                check(actor.catalog.eligible(event.conditions,actor),"Encontro disponível sem licença ou Nen")
                check(actor.choose(index),"Nova escolha executável")
                if actor.result.contains("· sucesso"):success+=1
                if actor.result.contains("· fracasso"):failure+=1
                check(not actor.choose(index),"Não duplica recompensas")
                check(actor.health>=0 and actor.health<=10 and actor.jenny>=0,"Recursos limitados")
                check(Store.save(actor,PATH)=="","Salva novo encontro")
                var loaded=Store.load_state(PATH,false)
                check(loaded.error=="" and loaded.state.serialize()==actor.serialize(),"Continuidade exata com e sem imagem")
                check(actor.serialize().version==before.version,"Formato v10 preservado")
    check(success>0 and failure>0,"Sucessos e fracassos dos novos testes")
    for name in ["mission","battle"]:
        var path="res://tests/fixtures/v011/"+name+".json"
        var bytes=FileAccess.get_file_as_string(path);var prior=JSON.parse_string(bytes)
        var loaded=Store.load_state(path,false);check(loaded.error=="","Save real v0.1.1 aceito")
        if loaded.error!="":continue
        var migrated=loaded.state
        var normalized=JSON.parse_string(JSON.stringify(migrated.serialize()))
        check(normalized.exam_history==[],"Save sem participação conserva histórico de exame vazio")
        normalized.erase("exam_history")
        check(normalized==prior,"Nenhum campo anterior alterado ao carregar v10")
        check(FileAccess.get_file_as_string(path)==bytes,"Save anterior não regravado")
        if name=="battle":
            migrated.Battle.act(migrated,"attack",migrated.battle.turn)
            var expected=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v011/battle_next.json"))
            normalized=JSON.parse_string(JSON.stringify(migrated.serialize()));normalized.erase("exam_history")
            check(normalized==expected,"Mesmo próximo turno, dano e RNG da v0.1.1")
    DirAccess.remove_absolute(PATH)
    print("IDENTIDADE 012: %d verificações, %d falhas; 16/182 ilustrados; novos testes: %d sucessos e %d fracassos" % [checks,failures,success,failure])
    quit(1 if failures else 0)
