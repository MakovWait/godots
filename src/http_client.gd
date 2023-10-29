extends Node


func async_http_get(url, headers=[], download_file=null):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var response = await async_http_get_using(http_request, url, headers, download_file)
	http_request.queue_free()
	return response


func async_http_get_using(http_request: HTTPRequest, url, headers=[], download_file=null):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)
	if download_file:
		http_request.download_file = download_file
	http_request.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await http_request.request_completed
	return response


class Response:
	var _resp: Array
	
	var result: int:
		get: return _resp[0]
	
	var code: int:
		get: return _resp[1]

	var headers: PackedStringArray:
		get: return _resp[2]

	var body: PackedByteArray:
		get: return _resp[3]

	func _init(resp: Array):
		_resp = resp
	
	func to_json(safe=true):
		return utils.response_to_json(_resp, safe)
	
	func get_string_from_utf8():
		return body.get_string_from_utf8()
	
	func to_response_info(host, download_file=null) -> ResponseInfo:
		var error_text = null
		var status = ""
		
		match result:
			HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH, HTTPRequest.RESULT_CONNECTION_ERROR, HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED:
				error_text = tr("Connection error, prease try again.")
				status = tr("Can't connect")
			HTTPRequest.RESULT_CANT_CONNECT, HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR:
				error_text = tr("Can't connect to host") + ": " + host
				status = tr("Can't connect")
			HTTPRequest.RESULT_NO_RESPONSE:
				error_text = tr("No response from host") + ": " + host
				status = tr("No response")
			HTTPRequest.RESULT_CANT_RESOLVE:
				error_text = tr("Can't resolve hostname") + ": " + host
				status = tr("Can't resolve.")
			HTTPRequest.RESULT_REQUEST_FAILED:
				error_text = tr("Request failed, return code") + ": " + str(code)
				status = tr("Request failed.")
			HTTPRequest.RESULT_DOWNLOAD_FILE_CANT_OPEN, HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR:
				error_text = tr("Cannot save response to") + ": " + download_file
				status = tr("Write error.")
			HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED:
				error_text = tr("Request failed, too many redirects")
				status = tr("Redirect loop.")
			HTTPRequest.RESULT_TIMEOUT:
				error_text = tr("Request failed, timeout")
				status = tr("Timeout.")
			_:
				if code != 200:
					error_text = tr("Request failed, return code") + ": " + str(code)
					status = tr("Failed") + ": " + str(code)
		
		var result = ResponseInfo.new()
		result.error_text = error_text
		result.status = status
		return result


class ResponseInfo:
	var status
	var error_text
