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
Settings used to modify and compress each invidual mime type output you specify on the fly.

I decided to make it as easy to use and customisable as possible to help the community that will use this.
]]
local content_type_list = {
	{
		"text/html",
		ngx.shared.minify, --shared cache zone to use or empty string to not use ""
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{
			--[[
			Usage :
			Regex, Replacement
			Text, Replacement
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
		}
	},
	{
		"text/css",
		ngx.shared.minify, --shared cache zone to use or empty string to not use ""
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			--{"(//[^.*]*.\n)", "",},
			--{"(/%*[^*]*%*/)", "",},
			--{"%s%s+", "",},
			--{"[ \t]+$", "",},
		}
	},
	{
		"text/javascript",
		ngx.shared.minify, --shared cache zone to use or empty string to not use ""
		60, --ttl for cache or ""
		1, --enable logging 1 to enable 0 to disable
		{
			--[[
			Usage :
			Regex, Replacement
			]]
	    	--{"(//[^.*]*.\n)", "",},
			--{"(/%*[^*]*%*/)", "",},
			--{"%s%s+", "",},
			--{"[ \t]+$", "",},
		}
	},
	
}

--[[

DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOU ARE DOING.

^^^^^ YOU WILL MOST LIKELY BREAK THE SCRIPT SO TO CONFIGURE THE FEATURES YOU WANT JUST USE WHAT I GAVE YOU ABOVE. ^^^^^

THIS BLOCK IS ENTIRELY WRITTEN IN CAPS LOCK TO SHOW YOU HOW SERIOUS I AM.

]]

local ngx_req_get_headers = ngx.req.get_headers
local ngx_req_set_header = ngx.req.set_header
local ngx_header = ngx.header
--local string_find = string.find
local string_match = string.match
local string_gsub = string.gsub
local ngx_arg = ngx.arg
local ngx_log = ngx.log
-- https://openresty-reference.readthedocs.io/en/latest/Lua_Nginx_API/#nginx-log-level-constants
local ngx_LOG_TYPE = ngx.STDERR
local request_uri = ngx.var.request_uri or "/"
local ngx_exit = ngx.exit
local ngx_say = ngx.say
local ngx_HTTP_OK = ngx.HTTP_OK

local content_type = ngx_header["content-type"] or ""
for i=1,#content_type_list do
	--if string_find(content_type, ";") ~= nil then -- Check if content-type has charset config
		--content_type = string_match(content_type, "(.*)%;(.*)") --Split ;charset from header
	--end
	if string_match(content_type_list[i][1], content_type) then

		local cached = content_type_list[i][2] or ""
		if cached ~= "" then
			local ttl = content_type_list[i][3] or ""
			local req_headers = ngx_req_get_headers() --get all request headers
			local cookies = req_headers["cookie"] or "" --for dynamic pages
			local key = request_uri .. cookies
			local count = cached:get(key) or nil

			if count == nil then
				if content_type_list[i][4] == 1 then
					ngx_log(ngx_LOG_TYPE, " Not yet or expired cached putting into cache " )
				end
				
				
				local res = ngx.location.capture(request_uri)
				--ngx_log(ngx_LOG_TYPE, " response status is " .. res.status )
				if res then
					if res.body and res.status == 200 then
						local output_minified = res.body

						for x=1,#content_type_list[i][5] do
							output_minified = string_gsub(output_minified, content_type_list[i][5][x][1], content_type_list[i][5][x][2])
						end --end foreach regex check

						ngx_header.content_length = #output_minified
						ngx_header.content_type = content_type_list[i][1]
						cached:set(key, output_minified, ttl)
						ngx_say(output_minified)
						ngx_exit(ngx_HTTP_OK)
					end
				end

				break --break out loop since matched content-type header

			else
				if content_type_list[i][4] == 1 then
					ngx_log(ngx_LOG_TYPE, " Served from cache " )
				end

				local output_minified = cached:get(key)
				ngx_header.content_length = #output_minified
				ngx_header.content_type = content_type_list[i][1]
				ngx_say(output_minified)
				ngx_exit(ngx_HTTP_OK)
			end
		else --shared mem zone not specified
			local res = ngx.location.capture(request_uri)
			if res then
				if res.body and res.status == 200 then
					local output_minified = res.body

					for x=1,#content_type_list[i][5] do
						output_minified = string_gsub(output_minified, content_type_list[i][5][x][1], content_type_list[i][5][x][2])
					end --end foreach regex check

					ngx_header.content_length = #output_minified
					ngx_header.content_type = content_type_list[i][1]
					ngx_say(output_minified)
					ngx_exit(ngx_HTTP_OK)
				end
			end

			break --break out loop since matched content-type header

		end

	end --end content_type if check
end --end content_type foreach mime type table check
