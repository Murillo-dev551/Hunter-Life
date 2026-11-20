extends SceneTree
const State=preload("res://scripts/game_state.gd")
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
    checks+=1
    if not ok:failures+=1;push_error(label)
func fresh(seed_value: int,licensed: bool):
    var s=State.new();s.rng.seed=seed_value;s.start("Simulação");s.open_event("market")
    if licensed:
        s.exam={"status":"approved","sequence":[s.Exam.OPTIONS[0][0],s.Exam.OPTIONS[1][0],s.Exam.OPTIONS[2][0],s.Exam.OPTIONS[3][0]],"stage":4,"setbacks":0,"awarded":true}
        s.Items.apply(s,{"items_add":{"hunter_license":1}})
    return s
# A deterministic cautious policy, using only visible tests, costs and warnings.
func decision(s) -> int:
    var best=-1;var score=-10000.0
    for i in range(s.demo.choices.size()):
        if s.choice_reason(i)!="":continue
        var c: Dictionary=s.demo.choices[i]
        if c.has("mission_end") or c.get("failure",{}).get("death",false):continue
        var value=100.0
        if c.has("test"):value=float(s.Progress.chance(int(s.attributes[c.test.attribute]),int(c.test.difficulty)))
        if c.get("next","").ends_with("_failed"):value-=200
        if c.get("next","").ends_with("_done"):value+=2
        if c.has("battle"):value-=20
        value+=float(c.get("health",0))*5.0
        if value>score:score=value;best=i
    if best<0:
        for i in range(s.demo.choices.size()):
            if s.choice_reason(i)=="":return i
    return best
func run() -> void:
    var template=fresh(777,true);var results={}
    for profile in [5,8]:
        var report={}
        for id in template.catalog.mission_entries:
            report[id]={"completed":0,"failed":0,"abandoned":0,"health":0,"xp":0}
            for seed_value in range(20):
                var s=fresh(9000+seed_value,true)
                for attribute in s.attributes:s.attributes[attribute]=profile
                if profile==8:s.Items.apply(s,{"items_add":{"rope":1,"lantern":1,"map":1}})
                # fresh() may have already seen another opportunity, never the one reused below.
                s.missions.erase(id);s.open_event(template.catalog.mission_entries[id]);s.choose(0);s.advance()
                var turns=0
                while s.missions.get(id,"") in ["active","offered"] and s.health>0 and turns<20:
                    turns+=1
                    if s.Battle.active(s):
                        s.Battle.act(s,"attack",s.battle.turn)
                        if not s.Battle.active(s) and s.health>0:s.advance()
                    else:
                        var index=decision(s);check(index>=0,"Política cautelosa encontra alternativa")
                        if index<0:break
                        s.choose(index)
                        if s.health>0:s.advance()
                check(turns<20,"Missão encerra sem ciclo")
                var status: String=s.missions.get(id,"")
                check(status in ["completed","failed","abandoned"],"Desfecho do perfil")
                if status in report[id]:report[id][status]+=1
                if s.health>0 and s.demo.kind=="adventure_end":s.choose(0)
                report[id].health+=s.health
                report[id].xp+=10*(s.level-1)*(s.level+2)+s.xp
        results[str(profile)]=report
    var journeys={};var seen={}
    for scenario in ["ordinary","unlicensed","licensed"]:
        var licensed=scenario=="licensed"
        var report={"levels":{},"endings":{},"mission_offers":0,"hunter_offers":0,"max_choices":0,"nen_offers":0,"exam_offers":0}
        for seed_value in range(40):
            var s=fresh(10000+seed_value,licensed);var count=0
            while s.health>0 and s.demo.kind!="ending" and count<1200:
                seen[s.current_id]=true;count+=1
                if s.Battle.active(s):
                    s.Battle.act(s,"attack",s.battle.turn)
                else:
                    if s.selected_choice<0:
                        if s.demo.kind=="opportunity" and s.demo.has("mission"):
                            report.mission_offers+=1
                            if s.demo.mission_category=="hunter":
                                report.hunter_offers+=1
                                check(s.catalog.eligible({"licensed":true},s),"Toda oportunidade profissional exige licença real")
                        if s.current_id=="nen_offer":report.nen_offers+=1
                        if s.current_id=="exam_invite":report.exam_offers+=1
                        var index=decision(s)
                        if scenario=="ordinary" and s.current_id in ["nen_offer","exam_invite"]:index=s.demo.choices.size()-1
                        check(index>=0,"Jornada com ação disponível")
                        if index<0:break
                        check(s.choose(index),"Escolha de jornada executável")
                    else:check(s.advance(),"Continuidade da jornada")
                check(s.health>=0 and s.health<=10,"Saúde limitada")
            check(count<1200,"Jornada completa sem bloqueio")
            if scenario=="ordinary":check(s.exam.status=="unentered" and not s.nen.awakened,"Jornada comum não precisa de exame ou Nen")
            report.max_choices=maxi(report.max_choices,count)
            report.levels[str(s.level)]=int(report.levels.get(str(s.level),0))+1
            var ending="incapacity" if s.health==0 else s.current_id
            report.endings[ending]=int(report.endings.get(ending,0))+1
        journeys[scenario]=report
    FileAccess.open("res://tests/011_balance_results.json",FileAccess.WRITE).store_string(JSON.stringify({"profiles":results,"journeys":journeys,"reached":seen.keys()},"  "))
    print("BALANCEAMENTO 011: %d verificações, %d falhas; jornadas=%s; cenas=%d" % [checks,failures,journeys,seen.size()])
    quit(1 if failures else 0)
