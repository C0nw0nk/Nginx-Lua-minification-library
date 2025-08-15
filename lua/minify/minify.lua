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

lua_shared_dict minify 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;

Example nginx.conf :

This will run for all websites on the nginx server
http {
#nginx config settings etc
lua_shared_dict minify 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

This will make it run for this website only
server {
#nginx config settings etc
lua_shared_dict minify 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

This will run in this location block only
location / {
#nginx config settings etc
lua_shared_dict minify 10m; #Minified pages cache
access_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

]]

--[[
localize all standard Lua and ngx functions I use for better performance.
]]
local next = next
local type = type
local ngx = ngx
local ngx_req_get_headers = ngx.req.get_headers
local ngx_header = ngx.header
local ngx_var = ngx.var
--local string_find = string.find
local string_match = string.match
local string_gsub = string.gsub
local ngx_arg = ngx.arg
local ngx_log = ngx.log
-- https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/#nginx-log-level-constants
local ngx_LOG_TYPE = ngx.STDERR
local request_uri = ngx_var.request_uri or "/"
local ngx_exit = ngx.exit
local ngx_say = ngx.say
local ngx_status = ngx.status
--[[
End localization
]]

--[[
Settings used to modify and compress each invidual mime type output you specify on the fly.

I decided to make it as easy to use and customisable as possible to help the community that will use this.
]]
local minify_table = {
	{
		"text/html",
		ngx.shared.minify, --shared cache zone to use or empty string to not use ""
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{200,404,}, --response status codes to minify
		{"GET",}, --request method to cache
		{ --bypass on cookie
			{
				"logged_in", --cookie name
				"1", --cookie value
				0, --0 guest user cache only 1 both guest and logged in user cache useful if logged_in cookie is present then cache key will include cookies
			},
			--{"name1","value1",},
		}, --bypass on cookie
		{"/login.html","/administrator","/admin*.$",}, --bypass cache urls
		1, --Send cache status header X-Cache-Status: HIT, X-Cache-Status: MISS
		1, --if serving from cache or updating cache page remove cookie headers (for dynamic sites you should do this to stay as guest only cookie headers will be sent on bypass pages)
		request_uri,
		false, --true to use lua resty.http library if exist
		{ --Minification / Minify HTML output
			--[[
			Usage :
			Regex, Replacement
			Text, Replacement
			You can use this to alter contents of the page output.
			]]
			--Example :
			--{"replace me", " with me! ",},
			--{"<!--[^>]-->", "",}, --remove nulled out html example !! I DO NOT RECOMMEND REMOVING COMMENTS, THIS COULD BREAK YOUR ENTIRE WEBSITE FOR OLD BROWSERS, BE AWARE
			--{"(//[^.*]*.\n)", "",}, -- Example: this //will remove //comments (result: this remove)
			--{"(/%*[^*]*%*/)", "",}, -- Example: this /*will*/ remove /*comments*/ (result: this remove)
			--{"<style>(.*)%/%*(.*)%*%/(.*)</style>", "<style>%1%3</style>",},
			--{"<script>(.*)%/%*(.*)%*%/(.*)</script>", "<script>%1%3</script>",},
			--{"%s%s+", "",}, --remove blank characters from html
			--{"[ \t]+$", "",}, --remove break lines (execution order of regex matters keep this last)
			{"<!%-%-[^%[]-->", "",},
			{"%s%s+", " ",},
			{"\n\n*", " ",},
			{"\n*$", ""},
		},
	},
	{
		"text/css",
		ngx.shared.minify, --shared cache zone to use or empty string to not use ""
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{200,}, --response status codes to minify
		{"GET",}, --request method to cache
		{ --bypass on cookie
			{
				"logged_in", --cookie name
				"1", --cookie value
				0, --0 guest user cache only 1 both guest and logged in user cache
			},
			--{"name1","value1",},
		}, --bypass on cookie
		{"/login.html","/administrator","/admin*.$",}, --bypass cache urls
		1, --Send cache status header X-Cache-Status: HIT, X-Cache-Status: MISS
		1, --if serving from cache or updating cache page remove cookie headers (for dynamic sites you should do this to stay as guest)
		request_uri,
		false, --true to use lua resty.http library if exist
		{ --Minification / Minify HTML output
			--[[
			Usage :
			Regex, Replacement
			You can use this to alter contents of the page output.
			]]
			--{"(//[^.*]*.\n)", "",},
			--{"(/%*[^*]*%*/)", "",},
			--{"%s%s+", "",},
			--{"[ \t]+$", "",},
		},
	},
	{
		"text/javascript",
		ngx.shared.minify, --shared cache zone to use or empty string to not use ""
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{200,}, --response status codes to minify
		{"GET",}, --request method to cache
		{ --bypass on cookie
			{
				"logged_in", --cookie name
				"1", --cookie value
				0, --0 guest user cache only 1 both guest and logged in user cache
			},
			--{"name1","value1",},
		}, --bypass on cookie
		{"/login.html","/administrator","/admin*.$",}, --bypass cache urls
		1, --Send cache status header X-Cache-Status: HIT, X-Cache-Status: MISS
		1, --if serving from cache or updating cache page remove cookie headers (for dynamic sites you should do this to stay as guest)
		request_uri,
		false, --true to use lua resty.http library if exist
		{ --Minification / Minify HTML output
			--[[
			Usage :
			Regex, Replacement
			You can use this to alter contents of the page output.
			]]
	    	--{"(//[^.*]*.\n)", "",},
			--{"(/%*[^*]*%*/)", "",},
			--{"%s%s+", "",},
			--{"[ \t]+$", "",},
		},
	},
	
}

--[[

DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOU ARE DOING.

^^^^^ YOU WILL MOST LIKELY BREAK THE SCRIPT SO TO CONFIGURE THE FEATURES YOU WANT JUST USE WHAT I GAVE YOU ABOVE. ^^^^^

THIS BLOCK IS ENTIRELY WRITTEN IN CAPS LOCK TO SHOW YOU HOW SERIOUS I AM.

]]

--[[]]
local ngx_cookie_time = ngx.cookie_time
local ngx_time = ngx.time
local currenttime = ngx_time() --Current time on server
local expire_time = 8640000 --One day
set_cookie1 = "name1".."=".."1".."; path=/; expires=" .. ngx_cookie_time(currenttime+expire_time) .. "; Max-Age=" .. expire_time .. ";"
set_cookie2 = "name2".."=".."2".."; path=/; expires=" .. ngx_cookie_time(currenttime+expire_time) .. "; Max-Age=" .. expire_time .. ";"
set_cookie3 = ""--"logged_in".."=".."1".."; path=/; expires=" .. ngx_cookie_time(currenttime+expire_time) .. "; Max-Age=" .. expire_time .. ";"
set_cookies = {set_cookie1,set_cookie2,set_cookie3}
ngx_header["Set-Cookie"] = set_cookies --send client a cookie for their session to be valid
--[[]]

local function minification(content_type_list)
	local content_type = ngx_header["content-type"] or ""
	for i=1,#content_type_list do
		--if string_find(content_type, ";") ~= nil then -- Check if content-type has charset config
			--content_type = string_match(content_type, "(.*)%;(.*)") --Split ;charset from header
		--end
		if string_match(content_type_list[i][1], content_type) then
			if content_type_list[i][9] == 1 then
				ngx_header["X-Cache-Status"] = "MISS"
			end

			local request_method_match = 0
			local cookie_match = 0
			local request_uri_match = 0
			if content_type_list[i][6] ~= "" then
				for a=1, #content_type_list[i][6] do
					if ngx_var.request_method == content_type_list[i][6][a] then
						request_method_match = 1
						break
					end
				end
				if request_method_match == 0 then
					--ngx_log(ngx_LOG_TYPE, "request method not matched")
					return
				end
			end
			if content_type_list[i][7] ~= "" then
				local guest_or_logged_in = 0
				for a=1, #content_type_list[i][7] do
					local cookie_name = content_type_list[i][7][a][1]
					local cookie_value = content_type_list[i][7][a][2]
					guest_or_logged_in = content_type_list[i][7][a][3]
					local cookie_exist = ngx_var["cookie_" .. cookie_name] or ""
					if cookie_exist then
						if string_match(cookie_exist, cookie_value ) then
							cookie_match = 1
							break
						end
					end
				end
				if cookie_match == 1 then
					--ngx_log(ngx_LOG_TYPE, "cookie matched so bypass")
					if guest_or_logged_in == 0 then --if guest user cache only then bypass cache for logged in users
						return
					end
				end
			end
			if content_type_list[i][8] ~= "" then
				for a=1, #content_type_list[i][8] do
					if string_match(request_uri, content_type_list[i][8][a] ) then
						request_uri_match = 1
						break
					end
				end
				if request_uri_match == 1 then
					--ngx_log(ngx_LOG_TYPE, "request uri matched so bypass")
					return
				end
			end

			local map = {
				GET = ngx.HTTP_GET,
				HEAD = ngx.HTTP_HEAD,
				PUT = ngx.HTTP_PUT,
				POST = ngx.HTTP_POST,
				DELETE = ngx.HTTP_DELETE,
				OPTIONS = ngx.HTTP_OPTIONS,
				MKCOL= ngx.HTTP_MKCOL,
				COPY = ngx.HTTP_COPY,
				MOVE = ngx.HTTP_MOVE,
				PROPFIND = ngx.HTTP_PROPFIND,
				PROPPATCH = ngx.HTTP_PROPPATCH,
				LOCK = ngx.HTTP_LOCK,
				UNLOCK = ngx.HTTP_UNLOCK,
				PATCH = ngx.HTTP_PATCH,
				TRACE = ngx.HTTP_TRACE,
				CONNECT = ngx.HTTP_CONNECT,
			}
			ngx.req.read_body()
			local request_body = ngx.req.get_body_data()
			local request_body_file = ""
			if not request_body then
				local file = ngx.req.get_body_file()
				if file then
					request_body_file = file
				end
			end
			if request_body_file ~= "" then
				local fh, err = io.open(request_body_file, "rb")
				if err then
					ngx_status = ngx.HTTP_INTERNAL_SERVER_ERROR
					ngx_log(ngx_LOG_TYPE, "error reading request_body_file:", err)
					return
				end
				request_body = fh:read("*all")
				fh:close()
			end
			local req_headers = ngx_req_get_headers() --get all request headers

			local cached = content_type_list[i][2] or ""
			if cached ~= "" then
				local ttl = content_type_list[i][3] or ""
				local cookie_string = ""
				if cookie_match == 1 then
					local cookies = req_headers["cookie"] or "" --for dynamic pages
					if type(cookies) ~= "table" then
						--ngx_log(ngx_LOG_TYPE, " cookies are string ")
						cookie_string = cookies
					else
						--ngx_log(ngx_LOG_TYPE, " cookies are table ")
						for t=1, #cookies do
							cookie_string = cookie_string .. cookies[t]
						end
					end
				end
				--ngx_log(ngx_LOG_TYPE, " cookies are " .. cookie_string)
				local key = content_type_list[i][11] .. cookie_string
				local count = cached:get(key) or nil

				if count == nil then
					if #content_type_list[i][5] > 0 then
						--[[]]
						local pcall = pcall
						local require = require
						local restyhttp = pcall(require, "resty.http") --check if resty http library exists will be true or false
						if restyhttp and content_type_list[i][12] then
							local httpc = require("resty.http").new()
							local res = httpc:request_uri(content_type_list[i][11], {
								method = map[ngx_var.request_method],
								body = request_body, --ngx_var.request_body,
								headers = req_headers,
							})
							if res then
								for z=1, #content_type_list[i][5] do
									if #res.body > 0 and res.status == content_type_list[i][5][z] then
										local output_minified = res.body

										if content_type_list[i][13] ~= "" and #content_type_list[i][13] > 0 then
											for x=1,#content_type_list[i][13] do
												output_minified = string_gsub(output_minified, content_type_list[i][13][x][1], content_type_list[i][13][x][2])
											end --end foreach regex check
										end

										if content_type_list[i][4] == 1 then
											ngx_log(ngx_LOG_TYPE, " Page not yet cached or ttl has expired so putting into cache " )
										end
										ngx_header.content_length = #output_minified
										ngx_header.content_type = content_type_list[i][1]
										if content_type_list[i][9] == 1 then
											ngx_header["X-Cache-Status"] = "UPDATING"
										end
										if content_type_list[i][10] == 1 and cookie_match == 0 then
											ngx_header["Set-Cookie"] = nil
										end
										cached:set(key, output_minified, ttl)
										cached:set("s"..key, res.status, ttl)
										cached:set("h"..key, res.headers, ttl)
										if res.header ~= nil and type(res.headers) == "table" then
											for headerName, header in next, res.headers do
												--ngx_log(ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
												ngx_header[headerName] = header
											end
										end
										ngx_status = res.status
										ngx_say(output_minified)
										ngx_exit(content_type_list[i][5][z])
									end
								end
							end
						else
						--[[]]

							local res = ngx.location.capture(content_type_list[i][11], {
							method = map[ngx_var.request_method],
							body = request_body, --ngx_var.request_body,
							args = "",
							headers = req_headers,
							})
							if res then
								for z=1, #content_type_list[i][5] do
									if #res.body > 0 and res.status == content_type_list[i][5][z] then
										local output_minified = res.body

										if content_type_list[i][13] ~= "" and #content_type_list[i][13] > 0 then
											for x=1,#content_type_list[i][13] do
												output_minified = string_gsub(output_minified, content_type_list[i][13][x][1], content_type_list[i][13][x][2])
											end --end foreach regex check
										end

										if content_type_list[i][4] == 1 then
											ngx_log(ngx_LOG_TYPE, " Page not yet cached or ttl has expired so putting into cache " )
										end
										ngx_header.content_length = #output_minified
										ngx_header.content_type = content_type_list[i][1]
										if content_type_list[i][9] == 1 then
											ngx_header["X-Cache-Status"] = "UPDATING"
										end
										if content_type_list[i][10] == 1 and cookie_match == 0 then
											ngx_header["Set-Cookie"] = nil
										end
										cached:set(key, output_minified, ttl)
										cached:set("s"..key, res.status, ttl)
										cached:set("h"..key, res.header, ttl)
										if res.header ~= nil and type(res.header) == "table" then
											for headerName, header in next, res.header do
												--ngx_log(ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
												ngx_header[headerName] = header
											end
										end
										ngx_status = res.status
										ngx_say(output_minified)
										ngx_exit(content_type_list[i][5][z])
									end
								end
							end
						end
					end

					break --break out loop since matched content-type header

				else
					if content_type_list[i][4] == 1 then
						ngx_log(ngx_LOG_TYPE, " Served from cache " )
					end

					local output_minified = cached:get(key)
					local res_status = cached:get("s"..key)
					local res_header = cached:get("h"..key) or nil
					if res_header ~= nil and type(res_header) == "table" then
						for headerName, header in next, res_header do
							--ngx_log(ngx_LOG_TYPE, " header name" .. headerName .. " value " .. header )
							ngx_header[headerName] = header
						end
					end
					ngx_header.content_length = #output_minified
					ngx_header.content_type = content_type_list[i][1]
					if content_type_list[i][9] == 1 then
						ngx_header["X-Cache-Status"] = "HIT"
					end
					if content_type_list[i][10] == 1 and cookie_match == 0 then
						ngx_header["Set-Cookie"] = nil
					end
					ngx_status = res_status
					ngx_say(output_minified)
					ngx_exit(res_status)
				end
			else --shared mem zone not specified
				if #content_type_list[i][5] > 0 then
					local res = ngx.location.capture(content_type_list[i][11], {
					method = map[ngx_var.request_method],
					body = request_body, --ngx_var.request_body,
					args = "",
					headers = req_headers,
					})
					if res then
						for z=1, #content_type_list[i][5] do
							if #res.body > 0 and res.status == content_type_list[i][5][z] then
								local output_minified = res.body

								if content_type_list[i][13] ~= "" and #content_type_list[i][13] > 0 then
									for x=1,#content_type_list[i][13] do
										output_minified = string_gsub(output_minified, content_type_list[i][13][x][1], content_type_list[i][13][x][2])
									end --end foreach regex check
								end

								ngx_header.content_length = #output_minified
								ngx_header.content_type = content_type_list[i][1]
								ngx_status = res.status
								ngx_say(output_minified)
								ngx_exit(content_type_list[i][5][z])
							end
						end
					end
				end

				break --break out loop since matched content-type header

			end

		end --end content_type if check
	end --end content_type foreach mime type table check
end --end minification function
minification(minify_table)
