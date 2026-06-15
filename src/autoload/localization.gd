extends Node

# Localization (S6-017) — minimal autoload for in-game text translation.
#
# Loads design/l10n/strings.csv on _ready. CSV columns: key,en,zh (future:
# ja,ko, etc.). Default locale is determined at runtime; English is the
# fallback if the requested locale is missing.
#
# Public API:
#   Localization.t(key) -> String           # get localized text for key
#   Localization.trf(key, ...args) -> String  # get + format with %d/%s placeholders
#   Localization.set_locale(locale_str)       # switch language at runtime
#   Localization.get_locale() -> String       # current locale
#   Localization.has_key(key) -> bool         # true if key exists in CSV
#   Localization.key_count() -> int           # number of loaded keys (for tests)
#
# If a key is missing: returns "[key]" with brackets so missing translations
# are visible in the game (and in screenshots/tests).
#
# Files: design/l10n/strings.csv
# Format: key,en,zh (UTF-8, first row is header).

const _CSV_PATH: String = "res://design/l10n/strings.csv"

var _strings: Dictionary[String, Dictionary] = {}  # key -> {en: ..., zh: ...}
var _locale: String = "en"
var _loaded_ok: bool = false

func _ready() -> void:
    _load_csv()
    print("[Localization] ready: %d keys, locale=%s" % [_strings.size(), _locale])

func _load_csv() -> void:
    # S6-020 fix: in pck context, the .csv file is auto-imported as
    # Godot 4.6 Translation resources (strings.<locale>.translation).
    # Strategy:
    #   1. Try direct FileAccess read of the .csv (works in editor + dev)
    #   2. If that fails, load per-locale Translation resources
    #      (strings.en.translation, strings.zh.translation) — this is
    #      what the pck contains.
    var raw_text: String = ""
    if FileAccess.file_exists(_CSV_PATH):
        var f: FileAccess = FileAccess.open(_CSV_PATH, FileAccess.READ)
        if f != null:
            raw_text = f.get_as_text()
            f.close()
    if not raw_text.is_empty():
        _parse_csv_text(raw_text)
        return
    # Fallback: load from Translation resources (pck context)
    var base: String = _CSV_PATH.get_basename()
    var loaded: int = 0
    for locale in ["en", "zh"]:
        var tpath: String = "%s.%s.translation" % [base, locale]
        if not ResourceLoader.exists(tpath):
            continue
        var res: Resource = load(tpath)
        if res == null:
            continue
        # S6-020 fix: use get_class() check for OptimizedTranslation or Translation
        var res_class: String = res.get_class()
        if res_class != "Translation" and res_class != "OptimizedTranslation":
            continue
        # Use the base class method via Object.call() to avoid static-type check
        var message_list: PackedStringArray = res.call("get_message_list")
        var kcount: int = 0
        for key in message_list:
            if not _strings.has(key):
                _strings[key] = {}
            _strings[key][locale] = res.call("get_message", key)
            kcount += 1
        loaded += kcount
    if _strings.size() > 0:
        _loaded_ok = true
        print("[Localization] loaded via Translation resources: %d keys" % _strings.size())
    else:
        push_warning("[Localization] %s not found; tr() returns [key] for all" % _CSV_PATH)

func _parse_csv_text(raw_text: String) -> void:
    var lines: PackedStringArray = raw_text.split("\n")
    if lines.size() < 2:
        push_warning("[Localization] CSV needs at least header + 1 row")
        return
    var header: PackedStringArray = lines[0].split(",")
    if header.size() < 2:
        push_warning("[Localization] CSV header needs at least key + en")
        return
    var col_en: int = -1
    var col_zh: int = -1
    for i in header.size():
        match String(header[i]).strip_edges():
            "key": pass
            "en": col_en = i
            "zh": col_zh = i
    if col_en == -1:
        push_warning("[Localization] CSV missing 'en' column")
        return
    var row_count: int = 0
    for line_idx in range(1, lines.size()):
        var line: String = lines[line_idx]
        if line.strip_edges() == "":
            continue
        var row: PackedStringArray = line.split(",")
        if row.size() < 2:
            continue
        var key: String = String(row[0]).strip_edges()
        var entry: Dictionary = {}
        if col_en < row.size():
            entry["en"] = String(row[col_en])
        if col_zh != -1 and col_zh < row.size():
            entry["zh"] = String(row[col_zh])
        _strings[key] = entry
        row_count += 1
    _loaded_ok = row_count > 0

# Public: get translated string for key
func t(key: StringName) -> String:
    var s: String = String(key)
    if not _strings.has(s):
        return "[%s]" % s  # missing-key marker
    var entry: Dictionary = _strings[s]
    if entry.has(_locale):
        return String(entry[_locale])
    # Fallback to English
    if entry.has("en"):
        return String(entry["en"])
    return "[%s]" % s

# Public: get + format. Args are applied to %d/%s placeholders.
func trf(key: StringName, args: Array = []) -> String:
    var template: String = t(key)
    if args.is_empty():
        return template
    return template % args

# Public: switch locale at runtime (re-display happens via UI refresh hooks)
func set_locale(locale_str: String) -> void:
    _locale = locale_str
    locale_changed.emit()

# Public: current locale
func get_locale() -> String:
    return _locale

# Public: check if key exists
func has_key(key: StringName) -> bool:
    return _strings.has(String(key))

# Public: count of loaded keys
func key_count() -> int:
    return _strings.size()

# Signal: fired when set_locale is called. UI scripts can listen and refresh.
signal locale_changed
