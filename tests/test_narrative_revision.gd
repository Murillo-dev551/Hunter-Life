extends SceneTree
# Somente estes campos editoriais podem mudar na revisão 10A.
const PROSE = ["title", "chapter", "paragraphs", "label", "result"]
const EXPECTED_MECHANICS = "40382126e730e18a104797296c6eb6aa5312f0c4c9efa65965df004d29a9c258"
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
    call_deferred("run")
func mechanics(value: Variant) -> Variant:
    if value is Dictionary:
        var out: Dictionary = {}
        for key in value:
            if key not in PROSE: out[key] = mechanics(value[key])
        return out
    if value is Array:
        var out: Array = []
        for entry in value: out.append(mechanics(entry))
        return out
    return value
func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)
func run() -> void:
    var events: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/events.json"))
    # O contrato editorial da 10A protege os 58 eventos originais; 10B acrescenta outros.
    var originals: Array = events.slice(0,58).duplicate(true)
    # A 10C somente acrescenta alternativas; o contrato das escolhas anteriores permanece.
    var counts: Dictionary={"signal_roof":4,"blocked_passage":5,"exam_capture":4,"exam_team":5}
    for event in originals:
        if counts.has(event["id"]):event["choices"]=event["choices"].slice(0,counts[event["id"]])
    var digest: String = JSON.stringify(mechanics(originals)).sha256_text()
    print("ASSINATURA MECÂNICA: ", digest)
    check(digest == EXPECTED_MECHANICS, "Preserva integralmente os dados mecânicos da Etapa 9")
    check(events.size() == 80, "Preserva 78 acontecimentos e acrescenta dois aprendizados")
    for event in events:
        check(not event["paragraphs"].is_empty(), "Contexto presente: " + event["id"])
        for choice in event["choices"]:
            check(not choice["result"].strip_edges().is_empty(), "Consequência presente")
            if choice.has("failure"):
                check(choice["result"] != choice["failure"]["result"], "Sucesso e fracasso distintos")
    print("REVISÃO 10A: %d verificações, %d falhas" % [checks, failures])
    quit(1 if failures else 0)
