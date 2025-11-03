ngx.header.content_type = "application/text"
local param = ngx.var.arg_host -- ?host=value
if not param then
    ngx.status = 400
    ngx.say('missing host parameter')
    return
end
local file = io.open(string.format("/pxe_disabled/%s", param), "r")
ngx.status = 200
if file then
    file:close()
    ngx.say('true')
else
    ngx.say('false')
end
