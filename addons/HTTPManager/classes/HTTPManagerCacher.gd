extends RefCounted

var manager:HTTPManager

func cache_request( job:HTTPManagerJob ):
	#look in the cache
	var url = job.get_url()
	var filepath = get_cache_name(url)
	if FileAccess.file_exists ( filepath ):
		var file = FileAccess.open( filepath, FileAccess.READ )
		var cache_infos = file.get_pascal_string()
		var headers = extract_cache_info(cache_infos)
		
		#add cache headers
		for i in headers:
			match i:
				"if-none-match","etag":
					job.add_header( i, headers[i] )


func cache_response( job:HTTPManagerJob, result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray ):
	var cache:Dictionary
	cache.headers = headers
	var filepath:String = get_cache_name( job.get_url() )
	if response_code == 304:
		#not modified
		var file = FileAccess.open( filepath, FileAccess.READ )
		if file:
			var cache_infos = file.get_pascal_string()
			var cache_headers = extract_cache_info(cache_infos)
			if cache_headers.has("content-type"):
				cache.headers.append("content-type: "+cache_headers["content-type"])
			cache.body = file.get_buffer(file.get_length() - file.get_position())
			cache.from_cache = true
			return cache
		else:
			manager.e("got code 304 but cachefile not found")
	else:
		cache.from_cache = false
		cache.body = body
	
	#parse headers for extra infos for caching
	var cache_headers:Dictionary
	var cachable:bool = false
	for header in headers:
		var h = job._string_to_header( header )
		match h[0].to_lower():
			"etag":
				cache_headers["if-none-match"] = h[1]
				cachable = true
			"last-modified":
				cache_headers["if-modified-since"] = h[1]
				cachable = true
			"content-type":
				cache_headers["content-type"] = h[1]
	
	if not cachable:
		return cache
	
	#save cache with extra headers
	DirAccess.make_dir_recursive_absolute(filepath.get_base_dir())
	var file = FileAccess.open( filepath, FileAccess.WRITE )
	if file:
		file.store_pascal_string( encode_cache_info(cache_headers))
		file.store_buffer( body )
	else:
		manager.e("cachefile could not be written in \""+filepath+"\"")
		
	return cache


func get_cache_name( url:String ):
	var pi = HTTPManager.parse_url(url)
	var cache_dir = pi.host.replace(":","_")
	var cache_name = pi.query.uri_encode()
	var filename = manager.cache_directory+"/"+cache_dir+"/"+cache_name
	
	return filename


func extract_cache_info( str:String ) -> Dictionary:
	var result = {}
	var hs = str.split("\r\n",false)
	for ns in hs:
		var n = ns.split(":",true,1)
		result[n[0]] = n[1]
	
	return result


func encode_cache_info( cache_info:Dictionary ) -> String:
	var result = ""
	for i in cache_info:
		result += i+": "+cache_info[i]+"\r\n"
	
	return result



