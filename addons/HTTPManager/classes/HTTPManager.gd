extends Node
class_name HTTPManager

## a feature rich HTTP-Request-Manager
##
## [b]Features:[/b][br]
## 
## - multiply parrallel request queue managment[br]
## - add GET and POST variables[br]
## - add upload files via POST request[br]
## - decodes response on mime-type[br]
## - custom decoders for mime-type[br]
## - automatic progress display[br]
## 


##number of parallel http connections
@export var parallel_connections_count:int = 5
##The size of the buffer used and maximum bytes to read per iteration. See HTTPClient.read_chunk_size.
##Set this to a lower value (e.g. 4096 for 4 KiB) when downloading small files to decrease memory usage at the cost of download speeds.
@export var download_chunk_size:int = 65536 : 
	set( value ):
		download_chunk_size = value
		for pipe in _pipes:
			pipe.download_chunk_size = value
##If true, multithreading is used to improve performance.
@export var use_threads:bool = false :
	set( value ):
		use_threads = value
		for pipe in _pipes:
			pipe.use_threads = value
##If true, this header will be added to each request: Accept-Encoding: gzip, deflate telling servers that it's okay to compress response bodies.
@export var accept_gzip:bool = true :
	set( value ):
		accept_gzip = value
		for pipe in _pipes:
			pipe.accept_gzip = value
##Maximum allowed size for response bodies. If the response body is compressed, this will be used as the maximum allowed size for the decompressed body.
@export var body_size_limit:int = -1 :
	set( value ):
		body_size_limit = value
		for pipe in _pipes:
			pipe.body_size_limit = value

##Maximum number of allowed redirects.
@export var max_redirects:int = 8 :
	set( value ):
		max_redirects = value
		for pipe in _pipes:
			pipe.max_redirects = value

##If set to a value greater than 0.0 before the request starts, the HTTP request will time out after timeout seconds have passed and the request is not completed yet. For small HTTP requests such as REST API usage, set timeout to a value between 10.0 and 30.0 to prevent the application from getting stuck if the request fails to get a response in a timely manner. For file downloads, leave this to 0.0 to prevent the download from failing if it takes too much time.
@export var timeout:float = 0 :
	set( value ):
		timeout = value
		for pipe in _pipes:
			pipe.timeout = value
##maximal times the manager retries to request the job after failed connection
@export var max_retries:int = 3

@export_group("proxy")
##use proxy
@export var use_proxy:bool = false
@export var http_proxy:String = "127.0.0.1"
@export var http_port:int = 8080
@export var https_proxy:String = "127.0.0.1"
@export var https_port:int = 8080

@export_group("cache")
##use caching
@export var use_cache:bool = false
## cache directory
@export var cache_directory:String = "user://http-manager-cache"

@export_group("progress scene")
##the interval delay to update progress scene and fire progress signal
@export var signal_progress_interval:float = 0.5
##automatically display the progress scene when the queue is progressed
@export var display_progress:bool = false
##custom scene to display when the queue is progressed
@export var progress_scene:PackedScene = null

@export_group("")
##accept cookies
@export var accept_cookies:bool = false
##automatically go into pause mode when a job failed
@export var pause_on_failure:bool = false
##print debug messages
@export var print_debug:bool = false

##cache control module
var cacher = null

var _HTTPPipe = preload("res://addons/HTTPManager/classes/HTTPPipe.gd")
var _pipes:Array[HTTPRequest] = []
var _client:HTTPClient
var _jobs:Array[HTTPManagerJob] = []
##queue processing is currently paused when true
var is_paused:bool = false
##multipart post--data boundary
var content_boundary:String = "GodotHTTPManagerContentBoundaryString"
var _progress_timer:Timer
var _max_assigned_files:int = 0
var _progress_scene
var _cookies:Dictionary

var _mime_decoders:Dictionary

# retry _jobs on this request results
var _retry_on_result:Array = [
	HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH,
	HTTPRequest.RESULT_CANT_CONNECT,
		#Request failed while connecting.
	HTTPRequest.RESULT_CONNECTION_ERROR,
		#Request failed due to connection (read/write) error.
	HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR,
		#Request failed on SSL handshake.
	HTTPRequest.RESULT_NO_RESPONSE,
		#Request does not have a response (yet).
	HTTPRequest.RESULT_TIMEOUT,
	#------------
	#HTTPRequest.RESULT_CANT_RESOLVE,
		#Request failed while resolving.
	#HTTPRequest.RESULT_REQUEST_FAILED,
		#Request failed (currently unused).
	#HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED,
		#Request reached its maximum redirect limit, see max_redirects.
	#HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED,
		#Request exceeded its maximum size limit, see body_size_limit.
]

const _result_error_string = {
	0: "SUCCESS",
	1: "CHUNKED BODY SIZE MISMATCH",
	2: "CANT CONNECT",
	3: "CANT RESOLVE",
	4: "CONNECTION ERROR",
	5: "TLS HANDSHAKE ERROR",
	6: "NO RESPONSE",
	7: "BODY SIZE LIMIT EXCEEDED",
	8: "BODY DECOMPRESS FAILED",
	9: "REQUEST FAILED", # Godot 4.1 docs say this is unused but I got it somehow once while testing
	10: "CANT OPEN DOWNLOAD FILE",
	11: "DOWNLOAD FILE WRITE ERROR",
	12: "REDIRECT LIMIT REACHED",
	13: "TIMEOUT"
}

const common_mime_types = {
	"aac": "audio/aac",
	"abw": "application/x-abiword",
	"arc": "application/x-freearc",
	"avif": "image/avif",
	"avi": "video/x-msvideo",
	"azw": "application/vnd.amazon.ebook",
	"bin": "application/octet-stream",
	"bmp": "image/bmp",
	"bz": "application/x-bzip",
	"bz2": "application/x-bzip2",
	"cda": "application/x-cdf",
	"csh": "application/x-csh",
	"css": "text/css",
	"csv": "text/csv",
	"doc": "application/msword",
	"docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
	"eot": "application/vnd.ms-fontobject",
	"epub": "application/epub+zip",
	"gz": "application/gzip",
	"gif": "image/gif",
	"htm": "text/html",
	"html": "text/html",
	"ico": "image/vnd.microsoft.icon",
	"ics": "text/calendar",
	"jar": "application/java-archive",
	"jpeg": "image/jpeg",
	"jpg": "image/jpeg",
	"js": "text/javascript",
	"json": "application/json",
	"jsonld": "application/ld+json",
	"midi": "audio/midi, audio/x-midi",
	"mid": "audio/midi, audio/x-midi",
	"mjs": "text/javascript",
	"mp3": "audio/mpeg",
	"mp4": "video/mp4",
	"mpeg": "video/mpeg",
	"mpkg": "application/vnd.apple.installer+xml",
	"odp": "application/vnd.oasis.opendocument.presentation",
	"ods": "application/vnd.oasis.opendocument.spreadsheet",
	"odt": "application/vnd.oasis.opendocument.text",
	"oga": "audio/ogg",
	"ogv": "video/ogg",
	"ogx": "application/ogg",
	"opus": "audio/opus",
	"otf": "font/otf",
	"png": "image/png",
	"pdf": "application/pdf",
	"php": "application/x-httpd-php",
	"ppt": "application/vnd.ms-powerpoint",
	"pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
	"rar": "application/vnd.rar",
	"rtf": "application/rtf",
	"sh": "application/x-sh",
	"svg": "image/svg+xml",
	"tar": "application/x-tar",
	"tif, .tiff": "image/tiff",
	"ts": "video/mp2t",
	"ttf": "font/ttf",
	"txt": "text/plain",
	"vsd": "application/vnd.visio",
	"wav": "audio/wav",
	"weba": "audio/webm",
	"webm": "video/webm",
	"webp": "image/webp",
	"woff": "font/woff",
	"woff2": "font/woff2",
	"xhtml": "application/xhtml+xml",
	"xls": "application/vnd.ms-excel",
	"xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
	"xml": "application/xml",
	"xul": "application/vnd.mozilla.xul+xml",
	"zip": "application/zip",
	"3gp": "video/3gpp",
	"3g2": "video/3gpp2",
	"7z": "application/x-7z-compressed"
}

##emited when the manager goes into pause mode
signal paused
##emited when the manager unpause and resumes the queue
signal unpaused
##emited when the all _jobs in the queue has finished
signal completed
##emited when progressed interval fires
signal progress
##emited when a job failed
signal job_failed
##emited when a job succeeded
signal job_succeded
##emited when a job is completed
signal job_completed


func _ready():
	#load all mime decoders in the addon decoders directory
	var dir_name = "res://addons/HTTPManager/classes/decoders/"
	var dir = DirAccess.open( dir_name )
	if dir:
		var files = dir.get_files()
		for file_name in files:
			_mime_decoders[file_name.get_basename()] = dir_name+file_name
	
	#make a HTTPClient for utillity use
	_client = HTTPClient.new()
	
	#create the progress timer
	_progress_timer = Timer.new()
	_progress_timer.wait_time = signal_progress_interval
	_progress_timer.connect("timeout", self._on_progress_interval )
	add_child(_progress_timer)
	_progress_timer.start()
	_progress_timer.paused = true
	
	#load the custom progress scene
	if not progress_scene:
		progress_scene = load("res://addons/HTTPManager/progress/progress.tscn")
	
	#add the progress scene
	_progress_scene = progress_scene.instantiate()
	add_child( _progress_scene )
	_progress_scene.hide()
	
	#add the progress scene
	cacher = load("res://addons/HTTPManager/classes/HTTPManagerCacher.gd").new()
	cacher.manager = self
	
	#create the http _pipes
	for i in parallel_connections_count:
		var pipe = _HTTPPipe.new()
		_pipes.append( pipe )
		pipe.manager = self
		pipe.accept_gzip = accept_gzip
		pipe.body_size_limit = body_size_limit
		pipe.download_chunk_size = download_chunk_size
		pipe.max_redirects = max_redirects
		pipe.use_threads = use_threads
		pipe.timeout = timeout
		add_child( pipe )


##creates a http job object with given request url
##returns HTTPManagerJob
func job( url:String ) -> HTTPManagerJob:
	var job = HTTPManagerJob.new()
	job._manager = self
	job.url = url
	#set defaults for jobs
	job.use_cache = use_cache
	#set proxy
	job.use_proxy = use_proxy
	return job


##add the job to the queue and starts processing the queue
func add_job( job:HTTPManagerJob ):
	_max_assigned_files += 1
	d("job added "+job.url)
	_jobs.append( job )
	dispatch()


func dispatch():
	if is_paused:
		#if paused dont dispacth a new job
		return
	
	#if _jobs in queue
	if _jobs.size() > 0:
		#check every pipe if not busy
		for pipe in _pipes:
			if not pipe.is_busy:
				#pop a job from the queue and pdispatch it
				var job = _jobs.pop_front()
				_progress_timer.paused = false
				if display_progress:
					_progress_scene.popup_centered()
				pipe.dispatch( job )
				
				if _jobs.size() <= 0:
					#when this was the last job in queue, return
					return


func query_string_from_dict( dict:Dictionary ):
	return _client.query_string_from_dict( dict )


func _on_pipe_request_completed():
	if _jobs.size() > 0:
		dispatch()
		return
	
	for pipe in _pipes:
		if pipe.is_busy:
			return
	
	#no more _jobs in queue or still in pipe, end execution
	_progress_timer.paused = true
	if display_progress:
		_progress_scene.hide()
	_max_assigned_files = 0
	emit_signal("completed")


func _on_progress_interval():
	var current_files = _jobs.size()
	var total_bytes:float = 0.00001
	var current_bytes:float = 0
	for pipe in _pipes:
		if pipe.is_busy:
			total_bytes += pipe.get_body_size ( )
			current_files += 1
			current_bytes += pipe.get_downloaded_bytes()
	
	if _progress_scene:
		emit_signal("progress", _max_assigned_files, current_files, total_bytes, current_bytes )
		_progress_scene.httpmanager_progress_update( _max_assigned_files, current_files, total_bytes, current_bytes )


##stops all _jobs and clears the queue
func clear():
	d("clear")
	_jobs.clear()
	for pipe in _pipes:
		pipe.reset()


##pauses queue execution 
##running requests will complete but no further requests will be started
func pause():
	d("paused")
	is_paused = true
	emit_signal("paused")


##resumes queue processing
func unpause():
	d("unpaused")
	is_paused = false
	emit_signal("unpaused")
	dispatch()


##cleares all cookies for domains ending with "clear_domain"
func clear_cookies( clear_domain:String="" ):
	for domain in _cookies:
		if domain.ends_with(clear_domain):
			d(_cookies[domain].size()+" cookies for "+domain+" cleared")
			_cookies.erase(domain)


func set_cookie( value:String, request_url:String ):
	if not accept_cookies:
		return
	var cookie = HTTPManagerCookie.new()
	cookie.manager = self
	cookie.parse( value, request_url )
	
		
static func parse_url( url:String ):
	var result = {
		"scheme": "__empty__",
		"host": "__empty__",
		"query": "__empty__"
	}
	var reg = RegEx.new()
	reg.compile("^(.*)\\:\\/\\/([^\\/]*)\\/(.*)")
	var res = reg.search( url )
	if res and res.strings.size() == 4:
		result.scheme = res.strings[1] 
		result.host = res.strings[2]
		result.query = res.strings[3]
	elif res and res.strings.size() == 3:
		result.scheme = res.strings[1] 
		result.host = res.strings[2]
	
	return result


static func auto_mime( filename:String ):
	var ext = filename.get_extension()
	if common_mime_types.has(ext):
		return common_mime_types[ext]
	else:
		return "application/octet-stream"


func d( msg ):
	if print_debug:
		print( "HTTPManager: "+str(msg) )


static func e( msg ):
	printerr( "HTTPManager: "+str(msg) )

