extends Control


func _on_button_pressed():
	$HTTPManager.connect("completed",func(): print("all completed"))
	
	
	$HTTPManager.job(
		"https://de.wiktionary.org/wiki/Hilfe:Sonderzeichen/Tabelle"
	).charset(
		"utf-8"
	).on_success_set(
		$TextEdit, "text"
	).fetch()

	$HTTPManager.job(
		"https://support.oneskyapp.com/hc/en-us/article_attachments/202761727/example_2.json"
	).on_success( 
		func(response): print("This JSON is what i got:"); print(response.fetch())
	).fetch()

	$HTTPManager.job(
		"https://godotengine.org/storage/blog/covers/maintenance-release-godot-4-0-2.jpg"
	).on_success_set( 
		$TextureRect, "texture"
	).mime("image/texture").fetch()

	$HTTPManager.job(
		"https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
	).on_success_set( 
		$TextureRect2, "texture"
	).mime("image/texture").cache(false).on_success(
		func( _response ): print("download finished, not from cache")
	).fetch()

	$HTTPManager.job(
		"https://this.url.is.a.failure/"
	).on_success(
		func( _response ): print("realy?")
	).on_failure(
		func( _response ): print("i told this wont work!")
	).fetch()
	
	#--------------- use your own server here
	var server = "https://www.foo.bar"
	$HTTPManager.job(
		server
	).add_post_file(
		"uploadfile_1", "res://icon.svg"
	).add_post_buffer(
		"uploadfile_2", PackedByteArray([1,1,1]), "auto", "filename.ext"
	).on_success(
		func( _response ): print("uploaded")
	).on_failure(
		func( _response ): print("something bad happend")
	).fetch()

#	------ A download example
#
#	$HTTPManager.job(
#		"https://upload.wikimedia.org/wikipedia/commons/3/3f/Fronalpstock_big.jpg"
#	).download("C:/Users/Klaas/Downloads/video.mp4")


