extends Window


static func format_bytes( bytes:int ):
	var unit:String = "b"
	if bytes > 1048576:
		return str(snapped(float(bytes) / 1048576, 0.01)) + " mb"
	elif bytes > 1024:
		return str(snapped(float(bytes) / 1024, 1)) + " kb"
	else:
		return str(bytes) + " b"


func httpmanager_progress_update( total_files:int, current_files:int, total_bytes:int, current_bytes:int ):
	%files.text = str(total_files)+" / "+str(current_files)
	%progress_bytes.value = round((1.0 - current_files/(0.00001+total_files)) * 100)
	%bytes.text = format_bytes(total_bytes)+" / "+format_bytes(current_bytes)
	%progress_jobs.value = round(current_bytes/(0.00001+total_bytes) * 100)
