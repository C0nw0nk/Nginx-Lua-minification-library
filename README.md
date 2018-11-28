# Nginx-Lua-minification-library
A compression and minification library to minify static or dynamic assets like HTML PHP outputs CSS style sheets JS Javascript all text/html or plain text mime types that nginx can output that the browser will read so they are small compressed and have white space removed as well as helping reduce bandwidth consumption since the files served from nginx are now smaller.

# Information :

I built this script to compress and keep the specified mime types outputs small and minify the bandwidth that my servers have to use when serving these files to users.

If you have any bugs issues or problems just post a Issue request.

https://github.com/C0nw0nk/Nginx-Lua-minification-library/issues

If you fork or make any changes to improve this or fix problems please do make a pull request for the community who also use this. 

https://github.com/C0nw0nk/Nginx-Lua-minification-library/pulls

# Usage :

Add this to your Nginx configuration folder.

`nginx/conf/lua/minify`

Once installed into your `nginx/conf/` folder.

Add this to your HTTP block or it can be in a server or location block depending where you want this script to run for individual locations the entire server or every single website on the server.

```
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
```

### Example nginx.conf :

This will run for all websites on the nginx server

```
http {
#nginx config settings etc
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}
```

This will make it run for this website only

```
server {
#nginx config settings etc
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}
```

This will run in this location block only

```
location / {
#nginx config settings etc
header_filter_by_lua_file conf/lua/minify/minify_header.lua
body_filter_by_lua_file conf/lua/minify/minify.lua;
#more config settings and some server stuff
}
```


# Building your own regex rules to apply inside this script :

Using my code examples below copy and paste them to test and edit and build your own regex on the Lua demo site here :

https://www.lua.org/cgi-bin/demo

#### Examples :

##### Basic :
```
local string = "<style>lol1/* ok lol */lol2</style>"
local regex = "<style>(.*)%/%*(.*)%*%/(.*)</style>"
local replace_with = "<style>%1%3</style>"
local output = string.gsub(string, regex, replace_with)
print(output)
```

##### Advanced :
```
local add_to_string = [[added me!]]
local string = [[<style>lol1/* ok lol */lol2</style>]] .. add_to_string .. [[
hello world!
]]
local regex = "<style>(.*)%/%*(.*)%*%/(.*)</style>"
local replace_with = "<style>%1%3</style>"
local output = string.gsub(string, regex, replace_with)
print(output)
```
