extends RefCounted

var request_url:String
var request_query:String
var request_headers:Dictionary
var request_get:Dictionary
var request_post:Dictionary
var request_files:Array[Dictionary]

var result:int
var from_cache:bool = false

var response_code:int
var response_headers:Dictionary
var response_body:PackedByteArray
var response_mime:Array
var response_charset:String
var forced_mime:Array[String]
var forced_charset:String

func fetch():
	return response_body
