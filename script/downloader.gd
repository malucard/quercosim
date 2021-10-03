extends Node

signal loading(loaded, total)
signal error
signal loaded
signal requesting

var t = Thread.new()

func download(url, port, ssl):
	if(!t.is_active()):
		t.start(self, "_load", {"url": url, "ssl": ssl})

func parse_url(base: String):
	var r_scheme = ""
	var r_host = ""
	var r_port = 0
	var r_path = ""
	var pos = base.find("://")
	if pos != -1:
		r_scheme = base.substr(0, pos + 3).to_lower()
		base = base.substr(pos + 3, base.length() - pos - 3)
	pos = base.find("/")
	if pos != -1:
		r_path = base.substr(pos, base.length() - pos)
		base = base.substr(0, pos)
	pos = base.find("@")
	if pos != -1:
		base = base.substr(pos + 1, base.length() - pos - 1)
	if base.begins_with("["):
		pos = base.rfind("]")
		if pos == -1:
			return ERR_INVALID_PARAMETER
		r_host = base.substr(1, pos - 1)
		base = base.substr(pos + 1, base.length() - pos - 1)
	else:
		if base.get_slice_count(":") > 1:
			return ERR_INVALID_PARAMETER
		pos = base.rfind(":")
		if pos == -1:
			r_host = base
			base = ""
		else:
			r_host = base.substr(0, pos)
			base = base.substr(pos, base.length() - pos)
	if r_host.is_empty():
		return ERR_INVALID_PARAMETER
	r_host = r_host.to_lower()
	if base.begins_with(":"):
		base = base.substr(1, base.length() - 1)
		if !base.is_valid_integer():
			return ERR_INVALID_PARAMETER
		r_port = base.to_int()
		if r_port < 1 || r_port > 65535:
			return ERR_INVALID_PARAMETER
	return [r_scheme, r_host, r_port, r_path]

func _load(params):
	var url = parse_url(params.url)
	var scheme = url[0]
	var domain = url[1]
	var port = -1 if url[2] == 0 else url[2]
	var path = url[3]
	var use_ssl = false
	if scheme == "https://":
		use_ssl = true
	elif scheme != "http://":
		emit_signal("error")
		return
	var http = HTTPClient.new()
	var err = http.connect_to_host(domain, port, use_ssl)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		print("Connecting to " + domain + "...")
		if OS.has_feature("web"):
			# Synchronous HTTP requests are not supported on the web,
			# so wait for the next main loop iteration.
			yield(Engine.get_main_loop(), "idle_frame")
		else:
			OS.delay_msec(200)
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	var headers = [
		"User-Agent: Pirulo/1.0 (Godot)",
		"Accept: */*"
	]
	err = http.request(HTTPClient.METHOD_GET, path, headers)
	if err != OK:
		emit_signal("error")
		return
	emit_signal("requesting")
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		print("Requesting " + path + "...")
		yield(Engine.get_main_loop(), "idle_frame")
	if http.get_status() != HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED:
		emit_signal("error")
		return
	if http.has_response():
		headers = http.get_response_headers_as_dictionary()
		while(http.get_status() == HTTPClient.STATUS_BODY):
			http.poll()
			var chunk = http.read_response_body_chunk()
			if(chunk.size() == 0):
				OS.delay_usec(100)
			else:
				rb = rb+chunk
				call_deferred("_send_loading_signal", rb.size(), http.get_response_body_length())
		call_deferred("_send_loaded_signal")
		http.close()
		return rb

func _send_loading_signal(l, t):
	emit_signal("loading", l, t)

func _send_loaded_signal():
	var r = t.wait_to_finish()
	emit_signal("loaded", r)
