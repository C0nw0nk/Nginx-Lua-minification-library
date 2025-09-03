--[[
Introduction and details :

Copyright Conor Mcknight

https://github.com/C0nw0nk/Nginx-Lua-minification-library

Disclaimer :
I am not responsible for what you do with this script nor liable,
This script was released under default Copyright Law as a proof of concept.
For those who want to know what that means for your use of this script read the following : http://choosealicense.com/no-license/

Information :
I built this script to compress and keep the specified mime types outputs small and minify the bandwidth that my servers have to use when serving these files to users.

If you have any bugs issues or problems just post a Issue request. https://github.com/C0nw0nk/Nginx-Lua-minification-library/issues

If you fork or make any changes to improve this or fix problems please do make a pull request for the community who also use this. https://github.com/C0nw0nk/Nginx-Lua-minification-library/pulls

Usage :

Add this to your Nginx configuration folder.

nginx/conf/lua/minify

Once installed into your nginx/conf/ folder.

Add this to your HTTP block or it can be in a server or location block depending where you want this script to run for individual locations the entire server or every single website on the server.

lua_shared_dict html_cache 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;

Example nginx.conf :

This will run for all websites on the nginx server
http {
#nginx config settings etc
lua_shared_dict html_cache 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

This will make it run for this website only
server {
#nginx config settings etc
lua_shared_dict html_cache 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

This will run in this location block only
location / {
#nginx config settings etc
lua_shared_dict html_cache 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

]]

--[[
localize all standard Lua and ngx functions I use for better performance.
]]
local localized = {}
localized.tostring = tostring
localized.next = next
localized.type = type
localized.string_match = string.match
localized.string_lower = string.lower
localized.string_gsub = string.gsub
localized.ngx = ngx
localized.ngx_req_get_headers = localized.ngx.req.get_headers
localized.ngx_req_read_body = localized.ngx.req.read_body
localized.ngx_req_get_body_data = localized.ngx.req.get_body_data
localized.ngx_req_get_body_file = localized.ngx.req.get_body_file
localized.ngx_header = localized.ngx.header
localized.ngx_var = localized.ngx.var
localized.ngx_status = localized.ngx.status
localized.ngx_exit = localized.ngx.exit
localized.ngx_say = localized.ngx.say
--HTTP overrides old nginx lua versions do not have the response status codes so i create them keeps the script backwards compatible
localized.ngx_HTTP_CONTINUE = localized.ngx.HTTP_CONTINUE or 100 --(100)
localized.ngx_HTTP_SWITCHING_PROTOCOLS = localized.ngx.HTTP_SWITCHING_PROTOCOLS or 101 --(101)
localized.ngx_HTTP_OK = localized.ngx.HTTP_OK or 200 --(200)
localized.ngx_HTTP_CREATED = localized.ngx.HTTP_CREATED or 201 --(201)
localized.ngx_HTTP_ACCEPTED = localized.ngx.HTTP_ACCEPTED or 202 --(202)
localized.ngx_HTTP_NO_CONTENT = localized.ngx.HTTP_NO_CONTENT or 204 --(204)
localized.ngx_HTTP_PARTIAL_CONTENT = localized.ngx.HTTP_PARTIAL_CONTENT or 206 --(206)
localized.ngx_HTTP_SPECIAL_RESPONSE = localized.ngx.HTTP_SPECIAL_RESPONSE or 300 --(300)
localized.ngx_HTTP_MOVED_PERMANENTLY = localized.ngx.HTTP_MOVED_PERMANENTLY or 301 --(301)
localized.ngx_HTTP_MOVED_TEMPORARILY = localized.ngx.HTTP_MOVED_TEMPORARILY or 302 --(302)
localized.ngx_HTTP_SEE_OTHER = localized.ngx.HTTP_SEE_OTHER or 303 --(303)
localized.ngx_HTTP_NOT_MODIFIED = localized.ngx.HTTP_NOT_MODIFIED or 304 --(304)
localized.ngx_HTTP_TEMPORARY_REDIRECT = localized.ngx.HTTP_TEMPORARY_REDIRECT or 307 --(307)
localized.ngx_HTTP_PERMANENT_REDIRECT = localized.ngx.HTTP_PERMANENT_REDIRECT or 308 --(308)
localized.ngx_HTTP_BAD_REQUEST = localized.ngx.HTTP_BAD_REQUEST or 400 --(400)
localized.ngx_HTTP_UNAUTHORIZED = localized.ngx.HTTP_UNAUTHORIZED or 401 --(401)
localized.ngx_HTTP_PAYMENT_REQUIRED = localized.ngx.HTTP_PAYMENT_REQUIRED or 402 --(402)
localized.ngx_HTTP_FORBIDDEN = localized.ngx.HTTP_FORBIDDEN or 403 --(403)
localized.ngx_HTTP_NOT_FOUND = localized.ngx.HTTP_NOT_FOUND or 404 --(404)
localized.ngx_HTTP_NOT_ALLOWED = localized.ngx.HTTP_NOT_ALLOWED or 405 --(405)
localized.ngx_HTTP_NOT_ACCEPTABLE = localized.ngx.HTTP_NOT_ACCEPTABLE or 406 --(406)
localized.ngx_HTTP_REQUEST_TIMEOUT = localized.ngx.HTTP_REQUEST_TIMEOUT or 408 --(408)
localized.ngx_HTTP_CONFLICT = localized.ngx.HTTP_CONFLICT or 409 --(409)
localized.ngx_HTTP_GONE = localized.ngx.HTTP_GONE or 410 --(410)
localized.ngx_HTTP_UPGRADE_REQUIRED = localized.ngx.HTTP_UPGRADE_REQUIRED or 426 --(426)
localized.ngx_HTTP_TOO_MANY_REQUESTS = localized.ngx.HTTP_TOO_MANY_REQUESTS or 429 --(429)
localized.ngx_HTTP_CLOSE = localized.ngx.HTTP_CLOSE or 444 --(444)
localized.ngx_HTTP_ILLEGAL = localized.ngx.HTTP_ILLEGAL or 451 --(451)
localized.ngx_HTTP_INTERNAL_SERVER_ERROR = localized.ngx.HTTP_INTERNAL_SERVER_ERROR or 500 --(500)
localized.ngx_HTTP_NOT_IMPLEMENTED = localized.ngx.HTTP_NOT_IMPLEMENTED or 501 --(501)
localized.ngx_HTTP_METHOD_NOT_IMPLEMENTED = localized.ngx.HTTP_METHOD_NOT_IMPLEMENTED or 501 --(501)
localized.ngx_HTTP_BAD_GATEWAY = localized.ngx.HTTP_BAD_GATEWAY or 502 --(502)
localized.ngx_HTTP_SERVICE_UNAVAILABLE = localized.ngx.HTTP_SERVICE_UNAVAILABLE or 503 --(503)
localized.ngx_HTTP_GATEWAY_TIMEOUT = localized.ngx.HTTP_GATEWAY_TIMEOUT or 504 --(504)
localized.ngx_HTTP_VERSION_NOT_SUPPORTED = localized.ngx.HTTP_VERSION_NOT_SUPPORTED or 505 --(505)
localized.ngx_HTTP_INSUFFICIENT_STORAGE = localized.ngx.HTTP_INSUFFICIENT_STORAGE or 507 --(507)
--HTTP Method overrides old nginx lua versions do not have some of these
localized.ngx_HTTP_GET = localized.ngx.HTTP_GET
localized.ngx_HTTP_HEAD = localized.ngx.HTTP_HEAD
localized.ngx_HTTP_PUT = localized.ngx.HTTP_PUT
localized.ngx_HTTP_POST = localized.ngx.HTTP_POST
localized.ngx_HTTP_DELETE = localized.ngx.HTTP_DELETE
localized.ngx_HTTP_OPTIONS = localized.ngx.HTTP_OPTIONS
localized.ngx_HTTP_MKCOL = localized.ngx.HTTP_MKCOL
localized.ngx_HTTP_COPY = localized.ngx.HTTP_COPY
localized.ngx_HTTP_MOVE = localized.ngx.HTTP_MOVE
localized.ngx_HTTP_PROPFIND = localized.ngx.HTTP_PROPFIND
localized.ngx_HTTP_PROPPATCH = localized.ngx.HTTP_PROPPATCH
localized.ngx_HTTP_LOCK = localized.ngx.HTTP_LOCK
localized.ngx_HTTP_UNLOCK = localized.ngx.HTTP_UNLOCK
localized.ngx_HTTP_PATCH = localized.ngx.HTTP_PATCH
localized.ngx_HTTP_TRACE = localized.ngx.HTTP_TRACE
--localized.ngx_HTTP_CONNECT = localized.ngx.HTTP_CONNECT --does not exist but put here never know in the future
localized.ngx_log = localized.ngx.log
-- https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/#nginx-log-level-constants
localized.ngx_LOG_TYPE = localized.ngx.STDERR
localized.scheme = localized.ngx_var.scheme --scheme is HTTP or HTTPS
localized.host = localized.ngx_var.host --host is website domain name
localized.request_uri = localized.ngx_var.request_uri or "/" --request uri is full URL link including query strings and arguements
localized.URL = localized.scheme .. "://" .. localized.host .. localized.request_uri
--[[
End localization
]]

--[[
Settings used to modify and compress each invidual mime type output you specify on the fly.

I decided to make it as easy to use and customisable as possible to help the community that will use this.
]]

--[[
This is the equivilant of proxy_cache or fastcgi_cache Just better.
lua_shared_dict html_cache 10m; #HTML pages cache
lua_shared_dict mp4_cache 300m; #video mp4 cache

as a example with php you can do this and STATIC pages ARE cached and DYNAMIC content for logged in users will NOT be cached.
<?php

//Just change the code for your CMS / APP Joomla / Drupal etc have plenty of examples.
if($user->guest = 1){
//User in not logged in is a guest
$cookie_name = "logged_in";
$cookie_value = "0";
setcookie($cookie_name, $cookie_value, time() + (86400 * 30), "/"); // 86400 = 1 day
}
else
{
//User is logged in
$cookie_name = "logged_in";
$cookie_value = "1";
setcookie($cookie_name, $cookie_value, time() + (86400 * 30), "/"); // 86400 = 1 day
}
?>
]]
localized.content_cache = {

	{
		".*", --regex match any site / path
		"text/html", --content-type valid types are text/css text/javascript
		--lua_shared_dict html_cache 10m; #HTML pages cache
		localized.ngx.shared.html_cache, --shared cache zone to use or empty string to not use "" lua_shared_dict html_cache 10m; #HTML pages cache
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{200,206,}, --response status codes to cache
		{"GET",}, --request method to cache
		{ --bypass cache on cookie
			{
				".*", --"logged_in",--cookie name regex ".*" for any cookie
				".*", --"1",--cookie value ".*" for any value
				1, --0 guest user cache only 1 both guest and logged in user cache useful if logged_in cookie is present then cache key will include cookies
			},
			--{"name1","value1",0,},
		}, --bypass cache on cookie
		{"/login.html","/administrator","/admin*.$",}, --bypass cache urls
		1, --Send cache status header X-Cache-Status: HIT, X-Cache-Status: MISS
		1, --if serving from cache or updating cache page remove cookie headers (for dynamic sites you should do this to stay as guest only cookie headers will be sent on bypass pages)
		localized.request_uri, --url to use you can do "/index.html", as an example localized.request_uri is best.
		false, --true to use lua resty.http library if exist if you set this to true you can change localized.request_uri above to "https://www.google.com/", as an example.
		{ --Content Modifier Modification/Minification / Minify HTML output
			--Usage :
			--Regex, Replacement
			--Text, Replacement
			--You can use this to alter contents of the page output.
			--Example :
			--{"replace me", " with me! ",},
			--{"</head>", "<script type='text/javascript' src='../jquery.min.js'></script></head>",} --inject javascript into html page
			--{"<!--[^>]-->", "",}, --remove nulled out html example !! I DO NOT RECOMMEND REMOVING COMMENTS, THIS COULD BREAK YOUR ENTIRE WEBSITE FOR OLD BROWSERS, BE AWARE
			--{"(//[^.*]*.\n)", "",}, -- Example: this //will remove //comments (result: this remove)
			--{"(/%*[^*]*%*/)", "",}, -- Example: this /*will*/ remove /*comments*/ (result: this remove)
			--{"<style>(.*)%/%*(.*)%*%/(.*)</style>", "<style>%1%3</style>",},
			--{"<script>(.*)%/%*(.*)%*%/(.*)</script>", "<script>%1%3</script>",},
			--{"%s%s+", "",}, --remove blank characters from html
			--{"[ \t]+$", "",}, --remove break lines (execution order of regex matters keep this last)
			--{"<!%-%-[^%[]-->", "",},
			{"%s%s+", " ",},
			{"\n\n*", " ",},
			{"\n*$", ""},
		},
		"", --1e+6, --Maximum content size to cache in bytes 1e+6 = 1MB content larger than this wont be cached empty string "" to skip
		"", --Minimum content size to cache in bytes content smaller than this wont be cached empty string "" to skip
		{"content-type","content-range","content-length","etag","last-modified","set-cookie",}, --headers you can use this to specify what headers you want to keep on your cache HIT/UPDATING output
	},
	{
		".*", --regex match any site / path
		"video/mp4", --content-type valid types are text/css text/javascript
		--lua_shared_dict mp4_cache 300m; #video mp4 cache
		localized.ngx.shared.mp4_cache, --shared cache zone to use or empty string to not use "" lua_shared_dict mp4_cache 300m; #video mp4 cache
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{200,206,}, --response status codes to cache
		{"GET",}, --request method to cache
		{ --bypass cache on cookie
			{
				"logged_in", --cookie name ".*" for any cookie
				"1", --cookie value ".*" for any value
				0, --0 guest user cache only 1 both guest and logged in user cache useful if logged_in cookie is present then cache key will include cookies
			},
			--{"name1","value1",0,},
		}, --bypass cache on cookie
		{"/login.html","/administrator","/admin*.$",}, --bypass cache urls
		1, --Send cache status header X-Cache-Status: HIT, X-Cache-Status: MISS
		1, --if serving from cache or updating cache page remove cookie headers (for dynamic sites you should do this to stay as guest only cookie headers will be sent on bypass pages)
		localized.request_uri, --url to use you can do "/index.html", as an example localized.request_uri is best.
		false, --true to use lua resty.http library if exist if you set this to true you can change localized.request_uri above to "https://www.google.com/", as an example.
		"", --content modified not needed for this format
		4e+7, --Maximum content size to cache in bytes 1e+6 = 1MB, 1e+7 = 10MB, 1e+8 = 100MB, 1e+9 = 1GB content larger than this wont be cached empty string "" to skip
		200000, --200kb --Minimum content size to cache in bytes content smaller than this wont be cached empty string "" to skip
		{"content-type","content-range","content-length","etag","last-modified","set-cookie",}, --headers you can use this to specify what headers you want to keep on your cache HIT/UPDATING output
	},

}


--[[

DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOU ARE DOING.

^^^^^ YOU WILL MOST LIKELY BREAK THE SCRIPT SO TO CONFIGURE THE FEATURES YOU WANT JUST USE WHAT I GAVE YOU ABOVE. ^^^^^

THIS BLOCK IS ENTIRELY WRITTEN IN CAPS LOCK TO SHOW YOU HOW SERIOUS I AM.

]]

--[[
local ngx_cookie_time = ngx.cookie_time
local ngx_time = ngx.time
local currenttime = ngx_time() --Current time on server
local expire_time = 8640000 --One day
set_cookie1 = "name1".."=".."1".."; path=/; expires=" .. ngx_cookie_time(currenttime+expire_time) .. "; Max-Age=" .. expire_time .. ";"
set_cookie2 = "name2".."=".."2".."; path=/; expires=" .. ngx_cookie_time(currenttime+expire_time) .. "; Max-Age=" .. expire_time .. ";"
set_cookie3 = ""--"logged_in".."=".."1".."; path=/; expires=" .. ngx_cookie_time(currenttime+expire_time) .. "; Max-Age=" .. expire_time .. ";"
set_cookies = {set_cookie1,set_cookie2,set_cookie3}
ngx_header["Set-Cookie"] = set_cookies --send client a cookie for their session to be valid
]]

localized.get_resp_content_type_counter = 0
local function get_resp_content_type(forced) --incase content-type header not yet exists grab it
	local resp_content_type = nil
	if forced == nil then
		localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+1
		if localized.ngx_header["content-type"] then
			--localized.ngx_log(localized.ngx_LOG_TYPE, " localized.ngx_header['content-type'] " .. localized.ngx_header["content-type"] )
			resp_content_type = localized.ngx_header["content-type"]
			return resp_content_type
		end
	end
	--made it this far still no content-type ?
	if localized.get_resp_content_type_counter > 1 then --so we dont run location capture multiple times on the first run it will either be content-type or nil
		return resp_content_type
	end
	--localized.ngx_log(localized.ngx_LOG_TYPE, " count is " .. localized.get_resp_content_type_counter )
	--local req_headers = localized.ngx_req_get_headers()
	local map = {
		GET = localized.ngx_HTTP_GET,
		HEAD = localized.ngx_HTTP_HEAD,
		PUT = localized.ngx_HTTP_PUT,
		POST = localized.ngx_HTTP_POST,
		DELETE = localized.ngx_HTTP_DELETE,
		OPTIONS = localized.ngx_HTTP_OPTIONS,
		MKCOL = localized.ngx_HTTP_MKCOL,
		COPY = localized.ngx_HTTP_COPY,
		MOVE = localized.ngx_HTTP_MOVE,
		PROPFIND = localized.ngx_HTTP_PROPFIND,
		PROPPATCH = localized.ngx_HTTP_PROPPATCH,
		LOCK = localized.ngx_HTTP_LOCK,
		UNLOCK = localized.ngx_HTTP_UNLOCK,
		PATCH = localized.ngx_HTTP_PATCH,
		TRACE = localized.ngx_HTTP_TRACE,
		CONNECT = localized.ngx_HTTP_CONNECT, --does not exist but put here never know in the future
	}
	local res = localized.ngx.location.capture(localized.request_uri, {
	method = map[localized.ngx_var.request_method],
	--headers = req_headers,
	})
	if res then
		if res.header ~= nil and localized.type(res.header) == "table" then
			for headerName, header in next, res.header do
				--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
				if localized.string_lower(localized.tostring(headerName)) == "content-type" then
					--localized.ngx_log(localized.ngx_LOG_TYPE, " localized.ngx.location.capture " .. header )
					resp_content_type = header
				end
			end
		end
	end
	localized.ngx_header["content-type"] = resp_content_type --set header as content-type be either nil or the content-type
	localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+2 --make sure we dont run again
	return resp_content_type

end
--localized.ngx_log(localized.ngx_LOG_TYPE, "[Anti-DDoS] Content-Type header is. " .. get_resp_content_type() )
--get_resp_content_type()

if localized.content_cache == nil or #localized.content_cache == 0 then
	--localized.ngx_log(localized.ngx_LOG_TYPE,  " resp_content_type before " .. get_resp_content_type() )
	get_resp_content_type(1) --fix for random bug where content-type output is application/octet-stream on text/html seems to only happen on a / directory not a /index.html
	--localized.ngx_log(localized.ngx_LOG_TYPE,  " resp_content_type after " .. get_resp_content_type() )
end

if localized.content_cache ~= nil and #localized.content_cache > 0 then

local function minification(content_type_list)
	for i=1,#content_type_list do
		if localized.string_match(localized.URL, content_type_list[i][1]) then --if our host matches one in the table
			if content_type_list[i][10] == 1 then
				localized.ngx_header["X-Cache-Status"] = "MISS"
			end

			local request_method_match = 0
			local cookie_match = 0
			local guest_or_logged_in = 0
			local request_uri_match = 0
			if content_type_list[i][7] ~= "" then
				for a=1, #content_type_list[i][7] do
					if localized.ngx_var.request_method == content_type_list[i][7][a] then
						request_method_match = 1
						break
					end
				end
				if request_method_match == 0 then
					--if content_type_list[i][5] == 1 then
						--localized.ngx_log(localized.ngx_LOG_TYPE, "request method not matched")
					--end
					--goto end_for_loop
				end
			end
			if content_type_list[i][8] ~= "" then
				for a=1, #content_type_list[i][8] do
					local cookie_name = content_type_list[i][8][a][1]
					local cookie_value = content_type_list[i][8][a][2]
					local cookie_exist = localized.ngx_var["cookie_" .. cookie_name] or ""
					if cookie_exist then
						if localized.string_match(cookie_exist, cookie_value ) then
							cookie_match = 1
							if content_type_list[i][8][a][3] == 1 then
								guest_or_logged_in = 1
							end
							break
						end
					end
				end
				if cookie_match == 1 then
					if guest_or_logged_in == 0 then --if guest user cache only then bypass cache for logged in users
						--goto end_for_loop
						--if content_type_list[i][5] == 1 then
							--localized.ngx_log(localized.ngx_LOG_TYPE, " GUEST ONLY cache " .. guest_or_logged_in )
						--end
					else
						--if content_type_list[i][5] == 1 then
							--localized.ngx_log(localized.ngx_LOG_TYPE, " BOTH GUEST and LOGGED_IN in cache " .. guest_or_logged_in )
						--end
						cookie_match = 0 --set to 0
					end
				end
			end
			if content_type_list[i][9] ~= "" then
				for a=1, #content_type_list[i][9] do
					if localized.string_match(localized.request_uri, content_type_list[i][9][a] ) then
						request_uri_match = 1
						break
					end
				end
				if request_uri_match == 1 then
					--if content_type_list[i][5] == 1 then
						--localized.ngx_log(localized.ngx_LOG_TYPE, "request uri matched so bypass")
					--end
					--goto end_for_loop
				end
			end

			if request_method_match == 1 and cookie_match == 0 and request_uri_match == 0 then

				--I use this to override the status output
				local function response_status_match(resstatus)
					--localized.ngx_log(localized.ngx_LOG_TYPE, " res status is " .. localized.tostring(resstatus) )
					if resstatus == 100 then
						return localized.ngx_HTTP_CONTINUE --(100)
					end
					if resstatus == 101 then
						return localized.ngx_HTTP_SWITCHING_PROTOCOLS --(101)
					end
					if resstatus == 200 then
						return localized.ngx_HTTP_OK --(200)
					end
					if resstatus == 201 then
						return localized.ngx_HTTP_CREATED --(201)
					end
					if resstatus == 202 then
						return localized.ngx_HTTP_ACCEPTED --(202)
					end
					if resstatus == 204 then
						return localized.ngx_HTTP_NO_CONTENT --(204)
					end
					if resstatus == 206 then
						return localized.ngx_HTTP_PARTIAL_CONTENT --(206)
					end
					if resstatus == 300 then
						return localized.ngx_HTTP_SPECIAL_RESPONSE --(300)
					end
					if resstatus == 301 then
						return localized.ngx_HTTP_MOVED_PERMANENTLY --(301)
					end
					if resstatus == 302 then
						return localized.ngx_HTTP_MOVED_TEMPORARILY --(302)
					end
					if resstatus == 303 then
						return localized.ngx_HTTP_SEE_OTHER --(303)
					end
					if resstatus == 304 then
						return localized.ngx_HTTP_NOT_MODIFIED --(304)
					end
					if resstatus == 307 then
						return localized.ngx_HTTP_TEMPORARY_REDIRECT --(307)
					end
					if resstatus == 308 then
						return localized.ngx_HTTP_PERMANENT_REDIRECT --(308)
					end
					if resstatus == 400 then
						return localized.ngx_HTTP_BAD_REQUEST --(400)
					end
					if resstatus == 401 then
						return localized.ngx_HTTP_UNAUTHORIZED --(401)
					end
					if resstatus == 402 then
						return localized.ngx_HTTP_PAYMENT_REQUIRED --(402)
					end
					if resstatus == 403 then
						return localized.ngx_HTTP_FORBIDDEN --(403)
					end
					if resstatus == 404 then
						return localized.ngx_HTTP_OK --override lua error attempt to set status 404 via localized.ngx_exit after sending out the response status 200
						--return localized.ngx_HTTP_NOT_FOUND --(404)
					end
					if resstatus == 405 then
						return localized.ngx_HTTP_NOT_ALLOWED --(405)
					end
					if resstatus == 406 then
						return localized.ngx_HTTP_NOT_ACCEPTABLE --(406)
					end
					if resstatus == 408 then
						return localized.ngx_HTTP_REQUEST_TIMEOUT --(408)
					end
					if resstatus == 409 then
						return localized.ngx_HTTP_CONFLICT --(409)
					end
					if resstatus == 410 then
						return localized.ngx_HTTP_GONE --(410)
					end
					if resstatus == 426 then
						return localized.ngx_HTTP_UPGRADE_REQUIRED --(426)
					end
					if resstatus == 429 then
						return localized.ngx_HTTP_TOO_MANY_REQUESTS --(429)
					end
					if resstatus == 444 then
						return localized.ngx_HTTP_CLOSE --(444)
					end
					if resstatus == 451 then
						return localized.ngx_HTTP_ILLEGAL --(451)
					end
					if resstatus == 500 then
						return localized.ngx_HTTP_INTERNAL_SERVER_ERROR --(500)
					end
					if resstatus == 501 then
						return localized.ngx_HTTP_NOT_IMPLEMENTED --(501)
					end
					if resstatus == 501 then
						return localized.ngx_HTTP_METHOD_NOT_IMPLEMENTED --(501)
					end
					if resstatus == 502 then
						return localized.ngx_HTTP_BAD_GATEWAY --(502)
					end
					if resstatus == 503 then
						return localized.ngx_HTTP_SERVICE_UNAVAILABLE --(503)
					end
					if resstatus == 504 then
						return localized.ngx_HTTP_GATEWAY_TIMEOUT --(504)
					end
					if resstatus == 505 then
						return localized.ngx_HTTP_VERSION_NOT_SUPPORTED --(505)
					end
					if resstatus == 507 then
						return localized.ngx_HTTP_INSUFFICIENT_STORAGE --(507)
					end
					--If none of above just pass the numeric status back
					return resstatus
				end

				local map = {
					GET = localized.ngx_HTTP_GET,
					HEAD = localized.ngx_HTTP_HEAD,
					PUT = localized.ngx_HTTP_PUT,
					POST = localized.ngx_HTTP_POST,
					DELETE = localized.ngx_HTTP_DELETE,
					OPTIONS = localized.ngx_HTTP_OPTIONS,
					MKCOL = localized.ngx_HTTP_MKCOL,
					COPY = localized.ngx_HTTP_COPY,
					MOVE = localized.ngx_HTTP_MOVE,
					PROPFIND = localized.ngx_HTTP_PROPFIND,
					PROPPATCH = localized.ngx_HTTP_PROPPATCH,
					LOCK = localized.ngx_HTTP_LOCK,
					UNLOCK = localized.ngx_HTTP_UNLOCK,
					PATCH = localized.ngx_HTTP_PATCH,
					TRACE = localized.ngx_HTTP_TRACE,
					CONNECT = localized.ngx_HTTP_CONNECT, --does not exist but put here never know in the future
				}

				--[[
				For debugging tests i have checked these and they work fine i am leaving this here for future refrence
				curl post request test - curl.exe "http://localhost/" -H "User-Agent: testagent" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-GB,en;q=0.5" -H "Accept-Encoding: gzip, deflate, br, zstd" -H "DNT: 1" -H "Connection: keep-alive" -H "Cookie: name1=1; name2=2; logged_in=1" -H "Upgrade-Insecure-Requests: 1" -H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: none" -H "Sec-Fetch-User: ?1" -H "Priority: u=0, i" -H "Pragma: no-cache" -H "Cache-Control: no-cache" --request POST --data '{"username":"xyz","password":"xyz"}' -H "Content-Type: application/json"
				curl post no data test - curl.exe "http://localhost/" -H "User-Agent: testagent" -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" -H "Accept-Language: en-GB,en;q=0.5" -H "Accept-Encoding: gzip, deflate, br, zstd" -H "DNT: 1" -H "Connection: keep-alive" -H "Cookie: name1=1; name2=2; logged_in=1" -H "Upgrade-Insecure-Requests: 1" -H "Sec-Fetch-Dest: document" -H "Sec-Fetch-Mode: navigate" -H "Sec-Fetch-Site: none" -H "Sec-Fetch-User: ?1" -H "Priority: u=0, i" -H "Pragma: no-cache" -H "Cache-Control: no-cache" --request POST -H "Content-Type: application/json"
				
				client_body_in_file_only on; #nginx config to test / debug on post data being stored in file incase of large post data sizes the nginx memory buffer was not big enough i turned this on to check this works as it should.
				]]
				localized.ngx_req_read_body()
				local request_body = localized.ngx_req_get_body_data()
				local request_body_file = ""
				if not request_body then
					local file = localized.ngx_req_get_body_file()
					if file then
						request_body_file = file
					end
					--client_body_in_file_only on; #nginx config to test / debug
					--localized.ngx_log(localized.ngx_LOG_TYPE, " request_body_file is " .. request_body_file )
				end
				if request_body_file ~= "" then
					local fh, err = io.open(request_body_file, "rb")
					if err then
						localized.ngx_status = localized.ngx_HTTP_INTERNAL_SERVER_ERROR
						localized.ngx_log(localized.ngx_LOG_TYPE, "error reading request_body_file:", err)
						return
						--goto end_for_loop
					end
					request_body = fh:read("*all")
					fh:close()
				end
				if request_body == nil then
					request_body = "" --set to empty string
				end

				local req_headers = localized.ngx_req_get_headers() --get all request headers

				local cached = content_type_list[i][3] or ""
				if cached ~= "" then
					local ttl = content_type_list[i][4] or ""
					local cookie_string = ""
					if guest_or_logged_in == 1 then
						local cookies = req_headers["cookie"] or "" --for dynamic pages
						if localized.type(cookies) ~= "table" then
							--localized.ngx_log(localized.ngx_LOG_TYPE, " cookies are string ")
							cookie_string = cookies
						else
							--localized.ngx_log(localized.ngx_LOG_TYPE, " cookies are table ")
							for t=1, #cookies do
								cookie_string = cookie_string .. cookies[t]
							end
						end
					else
						req_headers["cookie"] = "" --avoid cache poisoning by removing REQUEST header cookies to ensure user is logged out when the expected logged_in cookie is missing
					end
					--localized.ngx_log(localized.ngx_LOG_TYPE, " cookies are " .. cookie_string)
					
					--TODO: convert cache key to a smaller storage format to use less memory for storage perhaps hex or binary etc
					local key = localized.ngx_var.request_method .. localized.scheme .. "://" .. localized.host .. content_type_list[i][12] .. cookie_string .. request_body --fastcgi_cache_key / proxy_cache_key - GET - https - :// - localized.host - localized.request_uri - request_header["cookie"] - request_body
					--localized.ngx_log(localized.ngx_LOG_TYPE, " full cache key is " .. key)

					local content_type_cache = cached:get("content-type"..key) or nil

					if content_type_cache == nil then
						if #content_type_list[i][6] > 0 then

							local pcall = pcall
							local require = require
							local restyhttp = pcall(require, "resty.http") --check if resty http library exists will be true or false
							if restyhttp and content_type_list[i][13] then
								local httpc = require("resty.http").new()
								local res = httpc:request_uri(content_type_list[i][12], {
									method = map[localized.ngx_var.request_method],
									body = request_body, --localized.ngx_var.request_body,
									headers = req_headers,
								})
								if res then
									for z=1, #content_type_list[i][6] do
										if #res.body > 0 and res.status == content_type_list[i][6][z] then
											local output_minified = res.body

											local content_type_header_match = 0
											if res.headers ~= nil and localized.type(res.headers) == "table" then
												for headerName, header in next, res.headers do
													--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
													if localized.string_lower(localized.tostring(headerName)) == "content-type" then
														if localized.string_match(header, content_type_list[i][2]) == nil then
															--goto end_for_loop
															content_type_header_match = 1
														end
													end
												end
											end

											if content_type_header_match == 0 then
												localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+2 --make sure we dont run again

												local file_size_bigger = 0
												if content_type_list[i][15] ~= "" and #output_minified > content_type_list[i][15] then
													if content_type_list[i][5] == 1 then
														localized.ngx_log(localized.ngx_LOG_TYPE, " File size bigger than maximum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][15] )
													end
													--goto end_for_loop
													file_size_bigger = 1
												end

												local file_size_smaller = 0
												if content_type_list[i][16] ~= "" and #output_minified < content_type_list[i][16] then
													if content_type_list[i][5] == 1 then
														localized.ngx_log(localized.ngx_LOG_TYPE, " File size smaller than minimum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][16] )
													end
													--goto end_for_loop
													file_size_smaller = 1
												end

												if file_size_bigger == 0 and file_size_smaller == 0 then

													if content_type_list[i][14] ~= "" and #content_type_list[i][14] > 0 then
														for x=1,#content_type_list[i][14] do
															output_minified = localized.string_gsub(output_minified, content_type_list[i][14][x][1], content_type_list[i][14][x][2])
														end --end foreach regex check
													end

													if content_type_list[i][5] == 1 then
														localized.ngx_log(localized.ngx_LOG_TYPE, " Page not yet cached or ttl has expired so putting into cache " )
													end
													localized.ngx_header.content_type = content_type_list[i][2]
													if content_type_list[i][10] == 1 then
														localized.ngx_header["X-Cache-Status"] = "UPDATING"
													end
													cached:set(key, output_minified, ttl)
													cached:set("s"..key, res.status, ttl)
													if res.headers ~= nil and localized.type(res.headers) == "table" then
														for headerName, header in next, res.headers do
															local header_original = headerName --so we do not make the header all lower case on insert
															if content_type_list[i][17] ~= "" or #content_type_list[i][17] > 0 then
																for a=1, #content_type_list[i][17] do
																	if localized.string_lower(localized.tostring(header_original)) == localized.string_lower(content_type_list[i][17][a]) then
																		cached:set(localized.string_lower(localized.tostring(header_original))..key, header, ttl)
																	end
																end
															end
															--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
															localized.ngx_header[headerName] = header
														end
													end
													if content_type_list[i][11] == 1 and guest_or_logged_in == 0 then
														localized.ngx_header["Set-Cookie"] = nil
													end
													localized.ngx_header["Content-Length"] = #output_minified
													--localized.ngx_status = res.status
													localized.ngx_status = response_status_match(res.status)
													localized.ngx_say(output_minified)
													localized.ngx_exit(response_status_match(content_type_list[i][6][z]))
													--localized.ngx_exit(content_type_list[i][6][z])
													break
												end --file size bigger and smaller
											end
										end
									end
								end --end if res

							else

								local res = localized.ngx.location.capture(content_type_list[i][12], {
								method = map[localized.ngx_var.request_method],
								body = request_body, --localized.ngx_var.request_body,
								args = "",
								headers = req_headers,
								})
								if res then
									for z=1, #content_type_list[i][6] do
										if #res.body > 0 and res.status == content_type_list[i][6][z] then
											local output_minified = res.body

											local content_type_header_match = 0
											if res.header ~= nil and localized.type(res.header) == "table" then
												for headerName, header in next, res.header do
													--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
													if localized.string_lower(localized.tostring(headerName)) == "content-type" then
														if localized.string_match(header, content_type_list[i][2]) == nil then
															--goto end_for_loop
															content_type_header_match = 1
														end
													end
												end
											end

											if content_type_header_match == 0 then
												localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+2 --make sure we dont run again

												local file_size_bigger = 0
												if content_type_list[i][15] ~= "" and #output_minified > content_type_list[i][15] then
													if content_type_list[i][5] == 1 then
														localized.ngx_log(localized.ngx_LOG_TYPE, " File size bigger than maximum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][15] )
													end
													--goto end_for_loop
													file_size_bigger = 1
												end

												local file_size_smaller = 0
												if content_type_list[i][16] ~= "" and #output_minified < content_type_list[i][16] then
													if content_type_list[i][5] == 1 then
														localized.ngx_log(localized.ngx_LOG_TYPE, " File size smaller than minimum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][16] )
													end
													--goto end_for_loop
													file_size_smaller = 1
												end

												if file_size_bigger == 0 and file_size_smaller == 0 then

													if content_type_list[i][14] ~= "" and #content_type_list[i][14] > 0 then
														for x=1,#content_type_list[i][14] do
															output_minified = localized.string_gsub(output_minified, content_type_list[i][14][x][1], content_type_list[i][14][x][2])
														end --end foreach regex check
													end

													if content_type_list[i][5] == 1 then
														localized.ngx_log(localized.ngx_LOG_TYPE, " Page not yet cached or ttl has expired so putting into cache " )
													end
													localized.ngx_header.content_type = content_type_list[i][2]
													if content_type_list[i][10] == 1 then
														localized.ngx_header["X-Cache-Status"] = "UPDATING"
													end
													cached:set(key, output_minified, ttl)
													cached:set("s"..key, res.status, ttl)
													if res.header ~= nil and localized.type(res.header) == "table" then
														for headerName, header in next, res.header do
															local header_original = headerName --so we do not make the header all lower case on insert
															if content_type_list[i][17] ~= "" or #content_type_list[i][17] > 0 then
																for a=1, #content_type_list[i][17] do
																	if localized.string_lower(localized.tostring(header_original)) == localized.string_lower(content_type_list[i][17][a]) then
																		cached:set(localized.string_lower(localized.tostring(header_original))..key, header, ttl)
																	end
																end
															end
															--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
															localized.ngx_header[headerName] = header
														end
													end
													if content_type_list[i][11] == 1 and guest_or_logged_in == 0 then
														localized.ngx_header["Set-Cookie"] = nil
													end
													localized.ngx_header["Content-Length"] = #output_minified
													--localized.ngx_status = res.status
													localized.ngx_status = response_status_match(res.status)
													localized.ngx_say(output_minified)
													localized.ngx_exit(response_status_match(content_type_list[i][6][z]))
													--localized.ngx_exit(content_type_list[i][6][z])
													break
												end --file size bigger and smaller
											end
										end
									end
								end --end if res
							end
						end

					else --if content_type_cache == nil then

						if content_type_cache and localized.string_match(content_type_cache, content_type_list[i][2]) then
							localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+2 --make sure we dont run again

							if content_type_list[i][5] == 1 then
								localized.ngx_log(localized.ngx_LOG_TYPE, " Served from cache " )
							end

							local output_minified = cached:get(key)
							local res_status = cached:get("s"..key)

							--localized.ngx_header.content_type = content_type_list[i][2]
							if content_type_list[i][10] == 1 then
								localized.ngx_header["X-Cache-Status"] = "HIT"
							end
							if content_type_list[i][17] ~= "" or #content_type_list[i][17] > 0 then
								for a=1, #content_type_list[i][17] do
									local header_name = localized.string_lower(content_type_list[i][17][a])
									local check_header = cached:get(header_name..key) or nil
									if check_header ~= nil then
										--localized.ngx_log(localized.ngx_LOG_TYPE, " check_header " .. check_header )
										localized.ngx_header[header_name] = check_header
									end
								end
							end
							if content_type_list[i][11] == 1 and guest_or_logged_in == 0 or guest_or_logged_in == 1 then
								localized.ngx_header["Set-Cookie"] = nil
							end
							localized.ngx_header["Content-Length"] = #output_minified
							--localized.ngx_status = res_status
							localized.ngx_status = response_status_match(res_status)
							localized.ngx_say(output_minified)
							localized.ngx_exit(response_status_match(res_status))
							--localized.ngx_exit(res_status)

						end
					end --if content_type_cache == nil then

				else --shared mem zone not specified
					if #content_type_list[i][6] > 0 then
						--[[]]
						local pcall = pcall
						local require = require
						local restyhttp = pcall(require, "resty.http") --check if resty http library exists will be true or false
						if restyhttp and content_type_list[i][13] then
							local httpc = require("resty.http").new()
							local res = httpc:request_uri(content_type_list[i][12], {
								method = map[localized.ngx_var.request_method],
								body = request_body, --localized.ngx_var.request_body,
								headers = req_headers,
							})
							if res then
								for z=1, #content_type_list[i][6] do
									if #res.body > 0 and res.status == content_type_list[i][6][z] then
										local output_minified = res.body

										local content_type_header_match = 0
										if res.headers ~= nil and localized.type(res.headers) == "table" then
											for headerName, header in next, res.headers do
												--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
												if localized.string_lower(localized.tostring(headerName)) == "content-type" then
													if localized.string_match(header, content_type_list[i][2]) == nil then
														--goto end_for_loop
														content_type_header_match = 1
													end
												end
											end
										end

										if content_type_header_match == 0 then
											localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+2 --make sure we dont run again

											local file_size_bigger = 0
											if content_type_list[i][15] ~= "" and #output_minified > content_type_list[i][15] then
												if content_type_list[i][5] == 1 then
													localized.ngx_log(localized.ngx_LOG_TYPE, " File size bigger than maximum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][15] )
												end
												--goto end_for_loop
												file_size_bigger = 1
											end

											local file_size_smaller = 0
											if content_type_list[i][16] ~= "" and #output_minified < content_type_list[i][16] then
												if content_type_list[i][5] == 1 then
													localized.ngx_log(localized.ngx_LOG_TYPE, " File size smaller than minimum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][16] )
												end
												--goto end_for_loop
												file_size_smaller = 1
											end

											if file_size_bigger == 0 and file_size_smaller == 0 then

												if content_type_list[i][14] ~= "" and #content_type_list[i][14] > 0 then
													for x=1,#content_type_list[i][14] do
														output_minified = localized.string_gsub(output_minified, content_type_list[i][14][x][1], content_type_list[i][14][x][2])
													end --end foreach regex check
												end

												if res.headers ~= nil and localized.type(res.headers) == "table" then
													for headerName, header in next, res.headers do
														--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
														localized.ngx_header[headerName] = header
													end
												end
												--if content_type_list[i][11] == 1 and guest_or_logged_in == 0 then
													--localized.ngx_header["Set-Cookie"] = nil
												--end
												localized.ngx_header["Content-Length"] = #output_minified
												--localized.ngx_status = res.status
												localized.ngx_status = response_status_match(res.status)
												localized.ngx_say(output_minified)
												localized.ngx_exit(response_status_match(content_type_list[i][6][z]))
												--localized.ngx_exit(content_type_list[i][6][z])
												break
											end --file size bigger and smaller
										end
									end
								end
							end --end if res

						else
						--[[]]

							local res = localized.ngx.location.capture(content_type_list[i][12], {
							method = map[localized.ngx_var.request_method],
							body = request_body, --localized.ngx_var.request_body,
							args = "",
							headers = req_headers,
							})
							if res then
								for z=1, #content_type_list[i][6] do
									if #res.body > 0 and res.status == content_type_list[i][6][z] then
										local output_minified = res.body

										local content_type_header_match = 0
										if res.header ~= nil and localized.type(res.header) == "table" then
											for headerName, header in next, res.header do
												--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
												if localized.string_lower(localized.tostring(headerName)) == "content-type" then
													if localized.string_match(header, content_type_list[i][2]) == nil then
														--goto end_for_loop
														content_type_header_match = 1
													end
												end
											end
										end

										if content_type_header_match == 0 then
											localized.get_resp_content_type_counter = localized.get_resp_content_type_counter+2 --make sure we dont run again

											local file_size_bigger = 0
											if content_type_list[i][15] ~= "" and #output_minified > content_type_list[i][15] then
												if content_type_list[i][5] == 1 then
													localized.ngx_log(localized.ngx_LOG_TYPE, " File size bigger than maximum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][15] )
												end
												--goto end_for_loop
												file_size_bigger = 1
											end

											local file_size_smaller = 0
											if content_type_list[i][16] ~= "" and #output_minified < content_type_list[i][16] then
												if content_type_list[i][5] == 1 then
													localized.ngx_log(localized.ngx_LOG_TYPE, " File size smaller than minimum allowed not going to cache " .. #output_minified .. " and " .. content_type_list[i][16] )
												end
												--goto end_for_loop
												file_size_smaller = 1
											end

											if file_size_bigger == 0 and file_size_smaller == 0 then

												if content_type_list[i][14] ~= "" and #content_type_list[i][14] > 0 then
													for x=1,#content_type_list[i][14] do
														output_minified = localized.string_gsub(output_minified, content_type_list[i][14][x][1], content_type_list[i][14][x][2])
													end --end foreach regex check
												end

												if res.header ~= nil and localized.type(res.header) == "table" then
													for headerName, header in next, res.header do
														--localized.ngx_log(localized.ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
														localized.ngx_header[headerName] = header
													end
												end
												--if content_type_list[i][11] == 1 and guest_or_logged_in == 0 then
													--localized.ngx_header["Set-Cookie"] = nil
												--end
												localized.ngx_header["Content-Length"] = #output_minified
												--localized.ngx_status = res.status
												localized.ngx_status = response_status_match(res.status)
												localized.ngx_say(output_minified)
												localized.ngx_exit(response_status_match(content_type_list[i][6][z]))
												--localized.ngx_exit(content_type_list[i][6][z])
												break
											end --file size bigger and smaller
										end
									end
								end
							end --end if res
						end
					end

					--break --break out loop

				end --end shared mem zone
			end --if request_method_match == 1 and cookie_match == 0 and request_uri_match == 0 then
		end --end if URL match check
		--::end_for_loop::

		if i >= #content_type_list then --last occurance
			--localized.ngx_log(localized.ngx_LOG_TYPE,  "count is " .. i .. " " .. localized.get_resp_content_type_counter .. " resp_content_type before " .. get_resp_content_type() .. " and " .. localized.ngx_header["Content-Type"]  )
			get_resp_content_type(1) --fix for random bug where content-type output is application/octet-stream on text/html seems to only happen on a / directory not a /index.html
			--localized.ngx_log(localized.ngx_LOG_TYPE,  localized.get_resp_content_type_counter .. " resp_content_type after " .. get_resp_content_type() )
		end

	end --end content_type foreach mime type table check
end --end minification function

minification(localized.content_cache)
end
