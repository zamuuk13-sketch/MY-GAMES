extends Node

const LOG_PATH := "user://kings_parkour_log.txt"

var _file: FileAccess = null
var _started_at: int = 0

func _ready() -> void:
	_started_at = Time.get_ticks_msec()
	_file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if _file == null:
		push_error("Kings Parkour logger: não foi possível abrir o arquivo de log. Erro: " + error_string(FileAccess.get_open_error()))
		return

	_file.store_line("=== KINGS PARKOUR DEBUG LOG ===")
	_file.store_line("Data/hora: " + Time.get_datetime_string_from_system())
	_file.store_line("Godot: " + str(Engine.get_version_info().get("string", "desconhecida")))
	_file.store_line("Sistema: " + OS.get_name())
	_file.store_line("Arquivo: " + ProjectSettings.globalize_path(LOG_PATH))
	_file.store_line("================================")
	_file.flush()

	get_tree().tree_exiting.connect(_on_tree_exiting)
	write_info("Logger iniciado.")

func write_info(message: String) -> void:
	var line := "[%s] INFO: %s" % [Time.get_time_string_from_system(), message]
	print(line)
	_write_line(line)

func write_warning(message: String) -> void:
	var line := "[%s] WARNING: %s" % [Time.get_time_string_from_system(), message]
	push_warning(message)
	_write_line(line)

func write_error(message: String) -> void:
	var line := "[%s] ERROR: %s" % [Time.get_time_string_from_system(), message]
	push_error(message)
	_write_line(line)

func _write_line(line: String) -> void:
	if _file != null:
		_file.store_line(line)
		_file.flush()

func _on_tree_exiting() -> void:
	write_info("Árvore do jogo encerrando.")
	var elapsed_seconds: float = float(Time.get_ticks_msec() - _started_at) / 1000.0
	write_info("Tempo de execução: %.2f segundos." % elapsed_seconds)
	if _file != null:
		_file.store_line("=== FIM DO LOG ===")
		_file.flush()
		_file.close()
		_file = null
