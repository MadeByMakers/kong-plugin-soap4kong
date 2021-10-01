local BasePlugin = require "kong.plugins.base_plugin"
local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"
local cjson = require('cjson')
local template = require "resty.template"
local soap4kong = BasePlugin:extend()

-- set the plugin priority, which determines plugin execution order (Default: 2001)
soap4kong.PRIORITY = 2001
soap4kong.VERSION = "0.1.2-1"

local function getPathArgs()
    local url = kong.request.get_path()
    local paths = kong.router.get_route().paths
    
    for index = 1, #paths do
        if url:match(paths[index]) then
            local i,f = url:find(paths[index])
            return url:sub(f + 1)
        end
    end
    return nil
end

local function path(position)
    if type(position) == 'number' then
        local paths = getPathArgs()
        local i = 1
        for param in paths:gmatch("([^/]+)") do
            if position == i then
                return param
            end
            i = i + 1
        end

        return nil
    else
        return nil
    end
end

local function body(value)
    local data = cjson.decode(kong.request.get_raw_body())
    if not value or value == nil or value == "" then
        return data
    end
    local f, err = load("return function(data) return data."..value.." end")
    return f()(data)
end

local function arg()
    local data = path(1)
    if data == nil then
        data = kong.request.get_query_arg("arg")
        if data == nil then
            data = body()
        end
    end
    return data
end

-- Processing of incoming requests
-- runs in the 'access_by_lua_block'
-- @param plugin_conf Plugin configuration
function soap4kong:access(plugin_conf)
    soap4kong.super.access(self)

    kong.service.request.set_path(plugin_conf.service.endpoint)
    kong.service.request.set_header("X-SOAP-RequestAction", plugin_conf.service.operation)
    kong.service.request.set_header("Content-Type", "text/xml")
    kong.service.request.set_method("POST")

    local requestText = plugin_conf.mapping.request
    local data = cjson.decode(kong.request.get_raw_body())

    requestText = template.process(requestText, data)
    kong.service.request.set_raw_body(requestText)
end

function soap4kong:header_filter(plugin_conf)
    soap4kong.super.header_filter(self)
    kong.response.set_header("Content-Type", "application/json")
    kong.response.clear_header("Content-Length")
    kong.response.set_status(200)
end

function soap4kong:body_filter(plugin_conf)
    soap4kong.super.body_filter(self)
    
    -- Clear nginx buffers
    local ctx = ngx.ctx
    if ctx.buffers == nil then
        ctx.buffers = {}
        ctx.nbuffers = 0
    end

    -- Load response body
    local data = ngx.arg[1]
    local eof = ngx.arg[2]
    local next_idx = ctx.nbuffers + 1

    if not eof then
        if data then
            ctx.buffers[next_idx] = data
            ctx.nbuffers = next_idx
            ngx.arg[1] = nil
        end
        return
    elseif data then
        ctx.buffers[next_idx] = data
        ctx.nbuffers = next_idx
    end

    local table_response = table.concat(ngx.ctx.buffers)
    local responseSOAP = table_response:gsub("(<[<?]xml [^>]*>)", "")

    for a,b in responseSOAP:gmatch("<([^:]*):([^ >/]*)") do
        responseSOAP = responseSOAP:gsub(a..":"..b, b)
    end

    for a in responseSOAP:gmatch("[^<]*<[^ /]* ([^>]*)>[^>]*") do
        responseSOAP = responseSOAP:gsub(a,"")
    end
    
    local responseHadler = handler:new()
    local parser = xml2lua.parser(responseHadler)
    parser:parse(responseSOAP)

    local response_function, err = load("return "..plugin_conf.mapping.response)
    local respJson = response_function()(responseHadler.root.Envelope.Body)

    ngx.arg[1] = cjson.encode(respJson)
end

return soap4kong