extends Node


func async_http_get(url, headers=[]):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var response = await async_http_get_using(http_request, url, headers)
	http_request.queue_free()
	return response


func async_http_get_using(http_request: HTTPRequest, url, headers=[]):
	var default_headers = [Config.AGENT_HEADER]
	default_headers.append_array(headers)
	http_request.request(url, default_headers, HTTPClient.METHOD_GET)
	var response = await http_request.request_completed
	return response
