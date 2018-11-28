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


header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;

Example nginx.conf :

This will run for all websites on the nginx server
http {
#nginx config settings etc
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

This will make it run for this website only
server {
#nginx config settings etc
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}

This will run in this location block only
location / {
#nginx config settings etc
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
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
		{
			--[[
			Usage :
			Regex, Replacement
			Text, Replacement
			]]
			--Example :
			--{"replace me", " with me! ",},
			{"<!--(.*)-->", "",}, --remove nulled out html
			{"<style>(.*)%/%*(.*)%*%/(.*)</style>", "<style>%1%3</style>",}, --remove nulled out css style sheet code inline within the html page
			--{"<style>(.*)%/%*(.*)%*%/(.*)</style>", "<style>%1%3</style>",}, --TODO: Regex for inline <style type="text/css"></style> --remove nulled out css style sheet code inline within the html page
			{"<script>(.*)%/%*(.*)%*%/(.*)</script>", "<script>%1%3</script>",}, --remove nulled out javascript code inline within the html page
			--{"<script>(.*)%/%*(.*)%*%/(.*)</script>", "<script>%1%3</script>",}, --TODO: Regex for inline <script type="text/javascript"></script> --remove nulled out javascript code inline within the html page
			{"\n", " ",}, --replace new lines with a space (execution order of regex matters keep this last)
		}
	},
	
	{
		"text/css",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},

	--javascript has allot of different mime types i don't know why!?
	{
		"application/javascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"application/ecmascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"application/x-ecmascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"application/x-javascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/ecmascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript1.0",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript1.1",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript1.2",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript1.3",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript1.4",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/javascript1.5",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/jscript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/livescript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/x-ecmascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
	{
		"text/x-javascript",
		{
			--[[
			Usage :
			Regex, Replacement
			]]
			{"\n", " ",},
		}
	},
}

--[[

DO NOT TOUCH ANYTHING BELOW THIS POINT UNLESS YOU KNOW WHAT YOU ARE DOING.

^^^^^ YOU WILL MOST LIKELY BREAK THE SCRIPT SO TO CONFIGURE THE FEATURES YOU WANT JUST USE WHAT I GAVE YOU ABOVE. ^^^^^

THIS BLOCK IS ENTIRELY WRITTEN IN CAPS LOCK TO SHOW YOU HOW SERIOUS I AM.

]]

local content_type = ngx.header["content-type"]
for key, value in ipairs(content_type_list) do
	if value[1] == content_type then
		for k, v in ipairs(value[2]) do
			local output = ngx.arg[1]
			local output_minified = output

			output_minified, occurrences, errors = string.gsub(output_minified, v[1], v[2])

			if output_minified then
				--Modify the output to replace it with our minified output
				ngx.arg[1] = output_minified
			end

		end --end foreach regex check
	end --end content_type if check
end --end content_type foreach mime type table check