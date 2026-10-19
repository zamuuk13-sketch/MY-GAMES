extends Node

const LOG_PATH := "user://kings_parkour_log.txt"
var _file: FileAccess
var _started_at := 0

func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file == null:
		push_error("Kings Parkour logger: não foi possível abrir o arquivo de log. Erro: %s" % error_string(FileAccess.get_open_error()))
		return
	_file.store_line("=== KINGS PARKOUR DEBUG LOG ===")
	_file.store_line("Data/hora: " + Time.get_datetime_string_from_system(true, true))
	_file.store_line("Godot: " + Engine.get_version_info().string)
	_file.store_line("Sistema: " + OS.get_name())
	_file.store_line("Arquivo: " + ProjectSettings.globalize_path(LOG_PATH))
	_file.store_line("================================")
	_file.flush()
	get_tree().tree_exiting.connect(_on_tree_exiting)
	log("Logger iniciado.")

func log(message: String) -> void:
	var line := "[%s] INFO: %s" % [Time.get_time_string_from_system(), message]
	print(line)
	_write_line(line)

func warn(message: String) -> void:
	var line := "[%s] WARNING: %s" % [Time.get_time_string_from_system(), message]
	push_warning(message)
	_write_line(line)

func error(message: String) -> void:
	var line := "[%s] ERROR: %s" % [Time.get_time_string_from_system(), message]
	push_error(message)
	_write_line(line)

func _write_line(line: String) -> void:
	if _file != null:
		_file.store_line(line)
		_file.flush()

func _on_tree_exiting() -> void:
	log("Árvore do jogo encerrando.")
	log("Tempo de execução: %.2f segundos." % ((Time.get_ticks_msec() - _started_at) / 1000.0))
	if _file != null:
		_file.store_line("=== FIM DO LOG ===")
		_file.flush()
		_file.close()
		_file = null
