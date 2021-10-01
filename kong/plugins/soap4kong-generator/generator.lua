local generator = {}

local services  = kong.db.services
local routes    = kong.db.routes
local plugins   = kong.db.plugins

function generator.generateService(endpoint)
    local host = endpoint:match("[http|https]://([^/]*)/.*")
    local port = endpoint:match("[http|https]://[^/:]*:([^/]*)/.*")
    local protocol = "http"
    
    if endpoint:startswith("http:") and port == nil then
        port = "80"
    elseif endpoint:startswith("https:") and port == nil then
        port = "443"
        protocol = "https"
    end

    local inserted_service, err = services:select_by_name(host)
    
    if not inserted_service then
        if err then
            ngx.log(ngx.ERR, "inserted_service select: ERROR", err)
            return false, "inserted_service select: ERROR"
        else
            inserted_service, err = services:insert({
                name = host,
                host  = host,
                tags = {"generated-by-soap4kong"},
                protocol = protocol,
                port = tonumber(port)
            })
               
            if not inserted_service then
                ngx.log(ngx.ERR, "error creating the service: ", err)
                return false, "error creating the service"
            end
        end
    end

    return true, inserted_service
end

function generator.generateRoutes(inserted_service, config, wsdlDoc, xsd, operation)

    local endpoint = config.endpoint:match("[http|https]://[^/]*/(.*)")

    local requestNamespace, requestType = wsdlDoc:getInputType(operation)
    local responseNamespace, responseType = wsdlDoc:getOutputType(operation)

    local xmlRequest = xsd.generateRequest(requestNamespace, requestType)
    local responseExpression = xsd.generateResponse(responseNamespace, responseType)

    local conf = {
        service = {
            endpoint = "/"..endpoint,
            operation = operation
       },
       mapping = {
           request = xmlRequest,
           response = responseExpression
       }
    }
    
    local path = config.base_path
    
    if not config.base_path:endswith("/") then
        path = path.."/"
    end

    path = path..operation

    local inserted_route, err = routes:select_by_name(inserted_service.name.."_"..operation)

    if not inserted_route then
        if err then
            ngx.log(ngx.ERR, "inserted_route select: ERROR", err)
            return false, "inserted_route select: ERROR"
        else
            inserted_route, err = routes:insert({
                name = inserted_service.name.."_"..operation,
                tags = {"generated-by-soap4kong"},
                paths  = { path },
                service = inserted_service
            })

            if not inserted_route then
                ngx.log(ngx.ERR, "error creating the route '"..operation.."' failed", err)
                return false, "error creating the route '"..operation.."'"
            end
        end
    end

    local inserted_plugin, err = plugins:insert({
        name    = "soap4kong",
        config = conf,
        route = inserted_route
    })

    if not inserted_plugin then
        if tostring(err):match("UNIQUE violation") == nil then
            ngx.log(ngx.ERR, "inserted_plugin failed: ", err)
            return false, "error inserted_plugin: "..inserted_route.name
        end
    end

    return true, nil
end

return generator