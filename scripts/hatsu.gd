extends RefCounted
const CATEGORIES={"reinforce":"Reforço","emission":"Emissão","transmutation":"Transmutação","conjuration":"Materialização","manipulation":"Manipulação"}
const SPECS={"reinforce":["power","resistance"],"emission":["power","range","precision"],"transmutation":["restraint","mobility"],"conjuration":["resistance","coverage"],"manipulation":["objects","motor"]}
const NAMES={"reinforce":"Corpo Temperado","emission":"Projétil de Aura","transmutation":"Fio de Aura","conjuration":"Escudo Materializado","manipulation":"Agulha de Comando"}
const LABELS={"power":"Potência","resistance":"Resistência","range":"Alcance","precision":"Precisão","restraint":"Contenção","mobility":"Mobilidade","coverage":"Cobertura","objects":"Controle de Objetos","motor":"Comando Motor"}
const DESCRIPTIONS={"reinforce:power":"Aura aplicada a esforços intensos, em testes físicos específicos.","reinforce:resistance":"Amortece impactos específicos; não confere imunidade geral.","emission:power":"Impactos mais fortes em obstáculos adequados.","emission:range":"Alcança objetos distantes, com teste de Agilidade.","emission:precision":"Atinge mecanismos pequenos, com teste de Intelecto.","transmutation:restraint":"Filamento aderente e elástico. Um teste bem-sucedido causa 1 de dano, reduz em 1 o ataque atual e abre a próxima ação; não imobiliza. Exige ação comum antes de novo uso.","transmutation:mobility":"Apoio próximo: teste de Agilidade para reposicionar, reduzir em 2 o ataque atual e abrir a próxima ação. Não causa dano; falhar deixa o ataque passar. Exige ação comum entre usos.","conjuration:resistance":"Escudo de porte pessoal, mantido apenas durante a resposta atual. Teste de Intelecto: reduz até 4 de dano; falha reduz 1. Exige ação comum entre usos.","conjuration:coverage":"Barreira de porte pessoal para um contato ou passagem breve. Teste de Intelecto: reduz até 2 de dano; contra investida, cria abertura. Falha não protege. Exige ação comum entre usos.","manipulation:objects":"Fixa agulha em objeto pequeno e próximo. Teste de Intelecto: reduz até 1 do ataque atual e abre a próxima ação, sem dano. Sem objeto acessível, não pode usar. Não move estruturas grandes nem mecanismos fora de alcance. Uma ação comum entre usos.","manipulation:motor":"Precisa acertar a agulha no alvo vivo. Teste de Agilidade: reduz até 2 do ataque atual e abre a próxima ação, sem dano. Não suprime a resposta nem controla consciência ou ações complexas. Uma ação comum entre usos; não deixa controle permanente."}
static func fresh() -> Dictionary:return {"id":"","specialization":"","learned":false}
static func category(id: String) -> String:
    # Materialização é o nome já persistido para a categoria também chamada Conjuração.
    return CATEGORIES.get(id,"")
static func can_learn(state, id: String, spec: String) -> bool:
    return id in SPECS and spec in SPECS[id] and not state.hatsu["learned"] and state.nen["water_done"] and state.nen["mastery"]==3 and state.nen["category"]==category(id)
static func valid(v: Variant, state) -> bool:
    if not v is Dictionary or v.size()!=3 or not v.get("learned") is bool or not v.get("id") is String or not v.get("specialization") is String:return false
    if not v["learned"]:return v["id"]=="" and v["specialization"]==""
    return v["id"] in SPECS and v["specialization"] in SPECS[v["id"]] and state.nen["water_done"] and state.nen["mastery"]==3 and state.nen["category"]==category(v["id"])
static func apply(state, effect: Dictionary) -> String:
    if not effect.has("hatsu_learn"):return ""
    var data: Dictionary=effect["hatsu_learn"]
    if not can_learn(state,data["id"],data["specialization"]):return ""
    state.hatsu={"id":data["id"],"specialization":data["specialization"],"learned":true}
    return "\nHatsu desenvolvido: %s · %s." % [NAMES[data["id"]],LABELS[data["specialization"]]]
