extends RefCounted
## Retry eligibility uses unique experiences, not an invented calendar.
const REQUIRED_EXPERIENCES=6
const MIN_RETRY_HEALTH=5
static func outside(s,until: int=2147483647) -> int:
    var count=0
    for id in s.seen:
        var event: Dictionary=s.catalog.events[id]
        if event.get("adventure","")=="exam" or event.kind in ["hub","ending"]:continue
        if int(s.last_visit.get(id,0))>until:continue
        if id==s.current_id and s.selected_choice<0:continue
        count+=1
    return count
static func exam_flags(s) -> Dictionary:
    var flags={}
    for key in s.flags:
        if key.begins_with("exam_") and key!="exam_ignored":flags[key]=s.flags[key]
    return flags
static func history(s) -> Array:
    var rows: Array=s.exam_history.duplicate(true)
    if s.exam.status=="unentered":return rows
    if rows.is_empty():
        # Old saves had at most one attempt. Archive only known stored facts.
        var started=int(s.last_visit.get("exam_arrival",s.step+1 if s.exam.status=="active" else maxi(1,s.step)))
        var ended=0
        if s.exam.status!="active":
            for id in s.seen:
                if s.catalog.events[id].get("adventure","")=="exam" and id not in ["exam_invite","exam_info"]:ended=maxi(ended,int(s.last_visit[id]))
            ended=maxi(started,ended)
        rows.append({"status":s.exam.status,"started":started,"ended":ended,"outside":outside(s,ended) if ended>0 else 0,"offered":outside(s,ended) if ended>0 else 0,"offer_step":0,"sequence":s.exam.sequence.duplicate(),"stage":s.exam.stage,"setbacks":s.exam.setbacks,"flags":exam_flags(s)})
    if rows.back().status=="active":
        var row: Dictionary=rows.back()
        row.status=s.exam.status;row.sequence=s.exam.sequence.duplicate();row.stage=s.exam.stage;row.setbacks=s.exam.setbacks;row.flags=exam_flags(s)
        if s.exam.status!="active" and row.ended==0:row.ended=s.step;row.outside=outside(s);row.offered=row.outside
    return rows
static func retry_reason(s) -> String:
    if s.exam.status=="approved":return "A Licença Hunter já foi concedida; não há nova candidatura."
    if s.exam.status!="failed":return "Uma nova tentativa exige uma reprovação anterior."
    if s.flags.get("exam_ignored",false):return "Você decidiu não procurar outra seleção nesta jornada."
    if s.health<MIN_RETRY_HEALTH:return "Recupere ao menos %d de Saúde antes de outra viagem." % MIN_RETRY_HEALTH
    var row: Dictionary=history(s).back()
    var remaining=maxi(0,REQUIRED_EXPERIENCES-(outside(s)-int(row.outside)))
    if remaining>0:return "Viva mais %d acontecimento(s) fora do exame antes de outra candidatura." % remaining
    return ""
static func can_start(s) -> bool:return s.exam.status=="unentered" or retry_reason(s)==""
static func can_offer(s) -> bool:
    if s.exam.status=="unentered":return not s.flags.get("exam_ignored",false)
    if retry_reason(s)!="":return false
    return outside(s)-int(history(s).back().offered)>=REQUIRED_EXPERIENCES
static func offered(s) -> void:
    if s.exam.status!="failed":return
    s.exam_history=history(s);s.exam_history.back().offered=outside(s);s.exam_history.back().offer_step=s.step
static func begin(s,previous: Array) -> void:
    s.exam_history=previous
    s.exam_history.append({"status":"active","started":s.step+1,"ended":0,"outside":0,"offered":0,"offer_step":0,"sequence":s.exam.sequence.duplicate(),"stage":1,"setbacks":0,"flags":{}})
static func current_start(s) -> int:
    var rows=history(s)
    return int(rows.back().started) if not rows.is_empty() else 0
static func valid(value: Variant,s) -> bool:
    if not value is Array or value.size()>512:return false
    if s.exam.status=="unentered":return value.is_empty()
    if value.is_empty():return false
    var previous_end=0
    for i in range(value.size()):
        var row=value[i]
        if not row is Dictionary or row.get("status") not in ["active","approved","failed","withdrawn"] or not row.get("sequence") is Array or not row.get("flags") is Dictionary:return false
        for key in ["started","ended","outside","offered","offer_step","stage","setbacks"]:
            if not (row.get(key) is int or row.get(key) is float) or not is_finite(float(row[key])) or row[key]<0 or float(row[key])!=floor(float(row[key])):return false
        if row.started<1 or row.started>s.step+1 or row.started<previous_end or row.stage<1 or row.stage>4 or row.setbacks>100:return false
        if row.outside>s.seen.size() or row.offered>s.seen.size() or row.offer_step>s.step:return false
        if row.sequence.size()!=4:return false
        for n in range(4):
            if row.sequence[n] not in s.Exam.OPTIONS[n]:return false
        for flag in row.flags.values():
            if not flag is bool:return false
        if row.status=="active":
            if i!=value.size()-1 or row.ended!=0:return false
        elif row.ended<row.started or row.ended>s.step:return false
        if i<value.size()-1 and row.status!="failed":return false
        previous_end=row.ended
    var last: Dictionary=value.back()
    return last.status==s.exam.status and last.sequence==s.exam.sequence and last.stage==s.exam.stage and last.setbacks==s.exam.setbacks
