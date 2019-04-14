# Nginx-Lua-minification-library
A compression and minification library to minify static or dynamic assets like HTML PHP outputs CSS style sheets JS Javascript all text/html or plain text mime types that nginx can output that the browser will read so they are small compressed and have white space removed as well as helping reduce bandwidth consumption since the files served from nginx webserver are now smaller.

> Please note, this script will only remove comments, white spaces and breaklines from your code. So, this mean it will not "rebuild" your files in order to minify the code. If you want something similar, I recommend using [Pagespeed](https://developers.google.com/speed/pagespeed/module/ "Pagespeed") from Google

# Information :

I built this script to compress and keep the specified mime types outputs small and minify the bandwidth that my servers have to use when serving these files to users.

If you have any bugs issues or problems just post a Issue request.

https://github.com/C0nw0nk/Nginx-Lua-minification-library/issues

If you fork or make any changes to improve this or fix problems please do make a pull request for the community who also use this. 

https://github.com/C0nw0nk/Nginx-Lua-minification-library/pulls

# Usage :

Edit settings inside `minify.lua` to add your own mime types or improve my regex. (Please share your soloutions and additions)

https://github.com/C0nw0nk/Nginx-Lua-minification-library/blob/master/lua/minify/minify.lua#L69

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

# Requirements :
NONE! :D You only need Nginx + Lua to use my scripts.

###### Where can you download Nginx + Lua ?

Openresty provide Nginx + Lua builds for Windows Linux etc here.

https://openresty.org/en/download.html

Nginx4windows has Windows specific builds with Lua here.

http://nginx-win.ecsds.eu/

Or you can download the source code for Nginx here and compile Nginx yourself with Lua.

https://nginx.org/en/download.html

# About :

I was inspired to create this because of Cloudflare feature "Auto Minify" https://www.cloudflare.com/
```
Auto Minify

Reduce the file size of source code on your website.

What does Auto Minify do?

Auto Minify removes unnecessary characters from your source code (like whitespace, comments, etc.) without changing its functionality.

Minification can compress source file size which reduces the amount of data that needs to be transferred to visitors and thus improves page load times.
```

I love that feature so much ontop of having it enabled on all my Cloudflare proxied sites I decided to make it into a feature on my own servers so the traffic I send to cloudflare is also reduced in bandwidth too! (Every little helps right!)

Thank you to @Cloudflare for the inspiration and your community for all the love, A big thanks to the @openresty community you guys rock Lua rocks you are all so awesome!

Lets build a better internet together! Where Speed, Privacy, Security and Compression matter!

Here are links to my favorite communities :)

http://openresty.org/en/

https://community.cloudflare.com/
