extends SceneTree
## Development-only asset conversion. Input: JSON array of {id, path} originals.
func _initialize() -> void:
    var args=OS.get_cmdline_user_args()
    if args.size()!=1:push_error("Informe o arquivo de origens.");quit(1);return
    var entries=JSON.parse_string(FileAccess.get_file_as_string(args[0]))
    if not entries is Array:quit(1);return
    DirAccess.make_dir_recursive_absolute("res://assets/scenery")
    for entry in entries:
        if entry.id not in ["city","forest","road","inn","port","ruins","office","market"]:quit(1);return
        var image=Image.load_from_file(entry.path)
        if image==null:quit(1);return
        image.resize(960,roundi(960.0*image.get_height()/image.get_width()),Image.INTERPOLATE_LANCZOS)
        if image.save_webp("res://assets/scenery/"+entry.id+".webp",false)!=OK:quit(1);return
        print(entry.id," ",image.get_width(),"×",image.get_height())
    quit()
