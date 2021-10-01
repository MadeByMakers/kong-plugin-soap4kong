local generator = require "kong.plugins.soap4kong-generator.generator"
local wsdl = require "kong.plugins.soap4kong-generator.wsdl"
local xsd2xml = require "kong.plugins.soap4kong-generator.xsd2xml"

local validator = {}

function validator.validate_base_path(value)
    if not value:startswith("/") then
        return false, "must starts with '/'"
    end
    return true
end

function validator.validate_endpoint(value)
    if not value:startswith("http") then
        return false, "must starts with 'http' or 'https'"
    end
    return true
end

function validator.validate_wsdl(value)
    if not (value:startswith("?") or value:startswith("/") or value:startswith("http") or value:startswith("<")) then
        return false, "must be a url or wsdl as text."
    end
    return true
end

function validator.validate(config)

    local wsdlDoc = wsdl:new(config.wsdl, config.endpoint)
    local operations = wsdlDoc:getSOAPActions()
    
    local xsd = xsd2xml.new(wsdlDoc:getSchema())
    
    local sucess, service = generator.generateService(config.endpoint)
    if not sucess then
        return false, service
    end

    if #config.operations > 0 then
        for operation in pairs(config.operations) do
            local valid = false
    
            for name in pairs(operations) do
                if operations[name] == config.operations[operation] then
                    valid = true
                end
            end
    
            if not valid then
                return false, "operation '"..config.operations[operation].."' is not in wsdl"
            end
        end

        for operation in pairs(config.operations) do
            local sucess, message = generator.generateRoutes(service, config, wsdlDoc, xsd, config.operations[operation])
            if not sucess then
                return false, message
            end
        end
    else
        for name in pairs(operations) do
            local sucess, message = generator.generateRoutes(service, config, wsdlDoc, xsd, operations[name])
            if not sucess then
                return false, message
            end
        end
    end

    return true
end

return validator