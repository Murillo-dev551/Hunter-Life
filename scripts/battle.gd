extends RefCounted
const ENEMIES={"bandit":{"name":"Assaltante de estrada","description":"Avança sem muita disciplina e pode perder a coragem quando pressionado.","hp":6,"dc":12},"fighter":{"name":"Lutador experiente","description":"Uma praticante local observa hábitos e interrompe o treino antes de violência fatal.","hp":7,"dc":14},"candidate":{"name":"Daro, candidato competitivo","description":"Busca uma vitória limpa; a examinadora Selma observa também seu julgamento.","hp":7,"dc":14}}
const INTENTS={"strike":"Ergue o braço e encurta a distância.","charge":"Firma os pés e avança rapidamente em sua direção.","guard":"Mantém os braços junto ao tronco e acompanha seus movimentos.","prepare":"Recua um pé, ajusta a postura e ergue os braços.","hesitate":"Interrompe o avanço e olha para a rota de saída."}
const LABELS={"attack":"Atacar com Força","quick":"Atacar com Agilidade","defend":"Defender","dodge":"Esquivar","flee":"Fugir","yield":"Render-se","ten":"Ten: proteger o corpo","zetsu":"Zetsu: recuar discretamente","ren":"Ren: pressionar o adversário","hatsu":"Usar Hatsu"}
static func active(s) -> bool:return not s.battle.is_empty() and s.battle["outcome"]==""
static func object_target(s) -> String:
    # Os demais adversários atuais lutam sem equipamento acessível para esta técnica.
    return "a fivela solta do cinturão" if s.battle.get("enemy","")=="bandit" else ""
static func begin(s,id: String) -> void:
    if not s.battle.is_empty() or id not in ENEMIES:return
    s.battle={"enemy":id,"hp":ENEMIES[id]["hp"],"turn":1,"intent":"charge" if id=="bandit" else "prepare","opening":false,"last":"","repeat":0,"special_until":0,"outcome":"","log":[],"rewarded":false}
static func reason(s,id: String) -> String:
    if not active(s) or s.health<=0:return "Confronto encerrado."
    if id not in LABELS:return "Ação desconhecida."
    if id in ["ten","zetsu","ren"] and id not in s.nen["techniques"]:return "Técnica não aprendida."
    if id=="hatsu" and not s.hatsu["learned"]:return "Hatsu não desenvolvido."
    if id=="hatsu" and s.hatsu["id"]=="manipulation" and s.hatsu["specialization"]=="objects" and object_target(s)=="":return "Não há objeto pequeno acessível para fixar a agulha neste confronto."
    if id in ["ten","zetsu","ren","hatsu"] and int(s.battle["turn"])<int(s.battle["special_until"]):return "Recupere a concentração com uma ação comum antes de usar aura novamente."
    return ""
static func test(s,id: String) -> Dictionary:
    var b: Dictionary=s.battle
    var attribute: String="agility" if id in ["quick","dodge","flee","zetsu"] else "strength"
    var dc: int=int(ENEMIES[b["enemy"]]["dc"])
    if id in ["defend","ten","yield"]:return {}
    if id in ["flee","zetsu"]:dc=12 if b["enemy"]=="bandit" else 10
    if id=="ren":attribute="presence";dc+=1
    if id=="zetsu":dc-=2
    if id=="hatsu":
        if s.hatsu["id"]=="manipulation":
            attribute="intellect" if s.hatsu["specialization"]=="objects" else "agility"
            dc+=-2 if s.hatsu["specialization"]=="objects" else 1
        if s.hatsu["id"]=="conjuration":return {"attribute":"intellect","difficulty":maxi(2,dc-(1 if s.hatsu["specialization"]=="resistance" else 0))}
        if s.hatsu["id"]=="transmutation":
            attribute="agility"
            if s.hatsu["specialization"]=="mobility":return {"attribute":attribute,"difficulty":maxi(2,dc)}
        if s.hatsu["id"]=="emission":attribute="intellect" if s.hatsu["specialization"] in ["power","precision"] else "agility"
        if s.hatsu["specialization"]=="resistance":return {}
        if s.hatsu["specialization"]=="precision":dc-=3 if b["opening"] or b["intent"]=="prepare" else 1
    if id in ["attack","quick","ren","hatsu"]:
        if b["intent"]=="guard":dc+=3
        if b["opening"] or b["intent"]=="hesitate":dc-=2
    if b["enemy"] in ["fighter","candidate"] and b["last"]==id and int(b["repeat"])>=1:dc+=3
    if s.inventory["equipment"]["weapon"]=="knife" and b["enemy"]=="bandit" and id in ["attack","quick"]:dc-=1
    return {"attribute":attribute,"difficulty":maxi(2,dc)}
static func finish(s,outcome: String) -> void:
    var b: Dictionary=s.battle
    if b["outcome"]!="":return
    b["outcome"]=outcome
    var text: String={"victory":"Você vence sem matar o adversário.","enemy_yield":"O adversário desiste e encerra o confronto.","fled":"Você consegue fugir. Não é uma vitória.","yielded":"Você se rende. O confronto termina sem vitória.","incapacity":"Você recebe socorro e abandona a jornada por incapacidade, sem morte automática."}[outcome]
    if not b["rewarded"]:
        b["rewarded"]=true
        var reward: Dictionary=s.demo.get("battle_rewards",{}).get(outcome,{})
        if reward.has("next"):s.pending_next=reward["next"]
        var xp: int=int(reward.get("xp",0))
        var levels: int=s.Progress.award(s,xp)
        if levels>0:text+="\nNível %d alcançado · %d ponto(s) disponível(is)." % [s.level,s.points]
        if xp>0:text+="\n+%d XP" % xp
        var before: int=s.jenny
        s.jenny=maxi(0,s.jenny+int(reward.get("jenny",0)))
        if s.jenny!=before:text+="\n%+d Jenny." % (s.jenny-before)
    if s.health==0:s.active_adventure=false;s.current_adventure="";s.pending_next=""
    s.flags["battle_"+outcome]=true
    s.Exam.battle_end(s,outcome)
    s.result=text
    b["log"].append(text);s.records.append(text)
static func act(s,id: String, token: int) -> bool:
    if reason(s,id)!="" or int(s.battle["turn"])!=token:return false
    var b: Dictionary=s.battle
    var t: Dictionary=test(s,id)
    var success: bool=true
    var margin: int=0
    var text: String="Turno %d · %s" % [b["turn"],LABELS[id]]
    if not t.is_empty():
        var roll: int=s.rng.randi_range(1,20)
        margin=roll+int(s.attributes[t["attribute"]])-int(t["difficulty"]);success=margin>=0
        text+="\n%s: d20 %d + %d contra %d · %s" % [s.ATTRIBUTE_NAMES[t["attribute"]],roll,s.attributes[t["attribute"]],t["difficulty"],"sucesso" if success else "fracasso"]
    b["repeat"]=int(b["repeat"])+1 if b["last"]==id else 1;b["last"]=id
    if id in ["ten","zetsu","ren","hatsu"]:b["special_until"]=int(b["turn"])+2
    if id=="yield":b["log"].append(text);s.records.append(text);finish(s,"yielded");return true
    if id in ["flee","zetsu"] and success:
        if id=="zetsu":text+="\nVocê usa a rota de saída; Zetsu não oculta o corpo."
        b["log"].append(text);s.records.append(text);finish(s,"fled");return true
    var block: int=0
    var damage: int=0
    var defending: bool=id in ["defend","ten"] or (id=="hatsu" and s.hatsu["specialization"]=="resistance")
    if id=="hatsu" and s.hatsu["id"]=="manipulation":
        b["opening"]=success
        if success:
            if s.hatsu["specialization"]=="objects":
                block=1
                text+="\nVocê fixa uma agulha n%s e transmite um único puxão. O ajuste interrompe o equilíbrio do equipamento: até 1 de dano evitado nesta resposta e abertura para sua próxima ação." % object_target(s)
            else:
                block=2
                text+="\nA agulha atinge o membro que avançava. Um comando motor breve atrasa o movimento: até 2 de dano evitado nesta resposta e abertura para sua próxima ação. O adversário continua consciente e pode reagir."
            text+=" A agulha é recolhida e o comando termina aqui; não há controle mantido."
        else:text+="\nA agulha não se fixa no alvo. Você a recolhe sem transmitir o comando; o adversário mantém sua resposta."
    elif id=="hatsu" and s.hatsu["id"]=="transmutation":
        b["opening"]=success
        if success:
            if s.hatsu["specialization"]=="restraint":
                block=1;b["hp"]=maxi(0,int(b["hp"])-1)
                text+="\nO fio prende brevemente o braço: -1 Saúde do adversário e até 1 de dano evitado agora. Ele pode reagir; a tensão abre apenas sua próxima ação."
            else:
                block=2;text+="\nVocê usa um apoio próximo para sair da linha de impacto: até 2 de dano evitado agora e abertura na próxima ação. O fio é recolhido."
        else:text+="\nO fio perde a aderência antes de firmar o apoio. Você o recolhe sem impedir a resposta do adversário."
    elif id=="hatsu" and s.hatsu["id"]=="conjuration":
        var resistant: bool=s.hatsu["specialization"]=="resistance"
        block=(4 if success else 1) if resistant else (2 if success else 0)
        b["opening"]=success and not resistant and b["intent"]=="charge"
        text+="\nVocê posiciona o escudo de porte pessoal para esta resposta: proteção de até %d de dano. Ele se desfaz ao fim do movimento." % block if success else "\nO escudo se forma fora de posição e se desfaz: protege apenas um contato leve." if resistant else "\nA cobertura se forma tarde demais e não intercepta o ataque."
        if b["opening"]:text+=" A investida desviada deixa abertura apenas para sua próxima ação."
    elif defending:
        block=2 if int(b["repeat"])==1 else 0
        if id=="ten":block+=1
        if id=="hatsu":block+=2
        b["opening"]=b["intent"] in ["charge","strike"]
        text+="\nVocê prepara proteção; repetir a mesma defesa deixa de segurar o adversário."
    elif id=="dodge":
        block=99 if success else -1;b["opening"]=success
    elif success and id in ["attack","quick","ren","hatsu"]:
        damage=3+(1 if margin>=6 else 0)
        if id=="ren":damage+=1
        if id=="hatsu" and s.hatsu["specialization"]=="power":damage+=2
        if id=="hatsu" and s.hatsu["specialization"]=="range" and b["intent"] in ["prepare","charge"]:block=99;text+="\nVocê aproveita a distância antes que ele se aproxime."
        if id=="hatsu" and s.hatsu["specialization"]=="precision" and b["opening"]:damage+=1
        b["hp"]=maxi(0,int(b["hp"])-damage);b["opening"]=false
        text+="\n-%d Saúde do adversário." % damage
        if b["intent"]=="prepare":block=99;text+="\nA preparação foi interrompida."
    else:b["opening"]=false
    if b["hp"]<=0:
        b["log"].append(text);s.records.append(text);finish(s,"victory");return true
    var incoming: int=3 if b["intent"]=="charge" else 0 if b["intent"] in ["prepare","hesitate"] else 1 if b["intent"]=="guard" else 2
    if int(b["turn"])>=6:incoming=mini(4,maxi(2,incoming)+1+floori((int(b["turn"])-6)/4.0))
    if b["enemy"] in ["fighter","candidate"] and int(b["repeat"])>=2:incoming+=1
    var hit: int=maxi(0,incoming-block)
    if s.inventory["equipment"]["protection"]=="vest" and b["intent"]=="charge" and hit>=2:
        hit-=1;text+="\nO colete amorteceu parte do impacto."
    s.health=maxi(0,s.health-hit)
    text+="\n-%d Saúde (%d/10)." % [hit,s.health]
    b["log"].append(text);s.records.append(text)
    if s.health==0:finish(s,"incapacity");return true
    if b["enemy"]=="bandit" and b["hp"]<=2 and s.rng.randf()<0.35:finish(s,"enemy_yield");return true
    b["turn"]=int(b["turn"])+1
    if b["enemy"]=="bandit":b["intent"]="hesitate" if b["hp"]<=2 else "charge" if s.rng.randf()<0.4 else "strike"
    else:b["intent"]="strike" if b["intent"]=="prepare" else "prepare" if s.rng.randf()<0.5 else "guard"

    s.result=text
    return true
static func valid(v: Variant,s) -> bool:
    if not v is Dictionary:return false
    if v.is_empty():return true
    if v.size()!=11 or v.get("enemy") not in ENEMIES or v.get("intent") not in INTENTS:return false
    for key in ["hp","turn","repeat","special_until"]:
        if not (v.get(key) is int or v.get(key) is float) or not is_finite(float(v[key])) or float(v[key])!=floor(float(v[key])) or v[key]<0 or v[key]>100000:return false
    if v["hp"]>ENEMIES[v["enemy"]]["hp"] or v["turn"]<1 or not v.get("opening") is bool or not v.get("rewarded") is bool or not v.get("log") is Array:return false
    if not v.get("last") is String or (v["last"]!="" and v["last"] not in LABELS) or v.get("outcome") not in ["","victory","enemy_yield","fled","yielded","incapacity"]:return false
    for line in v["log"]:
        if not line is String:return false
    if (v["outcome"]!="")!=v["rewarded"]:return false
    if v["outcome"]=="" and (v["hp"]<=0 or s.health<=0):return false
    if v["outcome"]=="incapacity" and s.health!=0:return false
    if s.health==0 and v["outcome"]!="incapacity":return false
    if v["outcome"]=="victory" and v["hp"]!=0:return false
    return true
