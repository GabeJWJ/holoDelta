extends RefCounted
class_name HTTPManagerCookie

var manager:HTTPManager

var name:String = "--unnamed--"
var request_url:String
var value:String
var expires:int = -1
var max_age:int = -1
var path:String
var secure:bool
var domain:String
var http_only:bool #this can be irgnored completely
var same_site:String = "lax" #dont know how to use this by now ... maybe support is added later 

var _is_host_set:bool
var _is_secure_set:bool

func parse( _value:String, request_url:String ):
	var regex = RegEx.new()
	regex.compile("http[s]?:\\/\\/([^\\/]+)")
	var res = regex.search(request_url)
	if not res:
		return false
	domain = res.strings[1]

	var parts = _value.split(";")
	for part in parts:
		part = part.strip_edges()
		var sp = part.split("=")
		if sp.size() == 2:
			set_value(sp[0],sp[1])
		else:
			set_value(sp[0])
	
	if _is_host_set:
		if not secure:
			return false

		if not domain == "":
			return false

		if not path == "/":
			return false

		if not request_url.to_lower().begins_with("https"):
			return false

	if _is_secure_set:
		if not secure:
			return false

		if not request_url.to_lower().begins_with("https"):
			return false

	manager.d("Cookie set "+name+"="+str(value)+" for "+domain)
	if not manager._cookies.has(domain):
		manager._cookies[domain] = {}
	manager._cookies[domain][name] = self
	

func set_value( _name:String, _value=null ):
	_value = str(_value)
	match _name.to_lower():
		"max-age":
			max_age = _value.to_int()
			expires = Time.get_unix_time_from_system() + max_age
		"path":
			path = _value
		"secure":
			secure = true
		"domain":
			domain = _value
		"httponly":
			http_only = true
		"expires":
			#this is wrong and must be corrected
			#expires = Time.get_unix_time_from_datetime_string(_value)
			#not implemented yet
			pass
		"samesite":
			same_site = _value
		_:
			if _name.substr(0,7) == "__Host-":
				_is_host_set = true
				_name = _name.substr(7)
			if _name.substr(0,9) == "__Secure-":
				_is_secure_set = true
				_name = _name.substr(9)
			name = _name
			value = _value


func apply_if_valid( request_protocol, request_domain, request_path):
	#check path
	if not request_path.begins_with( path ):
		return ""
	
	#check secure protocol
	if secure and request_protocol != "https":
		return ""
	
	return name+"="+value+";"

