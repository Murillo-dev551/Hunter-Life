extends RefCounted
## Presentation metadata only: paths, never preloaded textures or gameplay state.
const PATH="res://data/scenery.json"
static var definitions: Dictionary={}
static func data() -> Dictionary:
    if not definitions.is_empty():return definitions
    var parsed=JSON.parse_string(FileAccess.get_file_as_string(PATH))
    if parsed is Dictionary:definitions=parsed
    return definitions
static func valid(id: Variant) -> bool:
    return id is String and data().has(id)
static func texture(id: String) -> Texture2D:
    var entry: Dictionary=data().get(id,{})
    var path: String=entry.get("path","")
    if path=="" or not ResourceLoader.exists(path,"Texture2D"):return null
    return ResourceLoader.load(path,"Texture2D") as Texture2D
