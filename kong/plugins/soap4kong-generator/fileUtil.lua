local ngx_http = require 'resty.http'

local obj = {}

function obj:downloadFile(url) 
    local httpc = ngx_http.new()

    local request_data = {
        ["method"] = "GET",
        ["ssl_verify"] = false,
    }

    local response, err = httpc:request_uri(url, request_data)

    if not response then
        error("[fileUtil]:downloadFile('"..url.."'): ", err)
    end

    return response.body
end

function obj:cleanXML(xml)
    xml = xml:gsub("(<[<?]xml [^>]*>)", "")

    for a,b in xml:gmatch("<([^: ]*):([^ >/]*)") do
        xml = xml:gsub(a..":"..b, b)
    end

    return xml
end

return obj