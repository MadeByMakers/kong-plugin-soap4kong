local fileUtil = require "kong.plugins.soap4kong-generator.fileUtil"
local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"

local xsd2xml = {}

local function is_array(t)
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

function xsd2xml.new(schema)
    local self = {}

    function self.load(schema)
        if type(schema) == 'string' and schema:startswith("http") then
            local xsd = fileUtil:downloadFile(schema)
            xsd = fileUtil:cleanXML(xsd)

            local xsd_handler = handler:new()
            local parser = xml2lua.parser(xsd_handler)
            parser:parse(xsd)
    
            self.schema = xsd_handler.root.schema
        else
            self.schema = schema
        end
        
        if self.schema.import then
            local index = 1
            if self.schema.import._attr then
                local imports = {}
                imports[index] = {}
                imports[index].xsd = xsd2xml.new(self.schema.import._attr.schemaLocation)
                self.schema.import = imports
            else
                for _, value in pairs(self.schema.import) do
                    self.schema.import[index].xsd = xsd2xml.new(value._attr.schemaLocation)
                    index = index + 1
                end
            end
        end
    end

    function self.getElementByName(namespace, name, kind)
        if kind == nil then kind = "element" end

        if self.schema._attr.targetNamespace == namespace then
            for key, value in pairs(self.schema[kind]) do
                if value._attr.name == name then
                    return self, value
                end
            end
        else
            for _, value in pairs(self.schema.import) do
                if value._attr.namespace == namespace then
                    return value.xsd.getElementByName(namespace, name, kind)
                end
            end
        end

        return nil, nil
    end

    function self.getNamespace(el, prefixedType)
        local type_splited = prefixedType:split(":")
        local prefix = type_splited[0]
        local name = type_splited[1]

        if el and el._attr["xmlns:"..prefix] then
            return el._attr["xmlns:"..prefix], name
        else
            return self.schema._attr["xmlns:"..prefix], name
        end
    end

    function self.log(text)
        print("\n"..text.."\n")
    end

    function self.getLength(obj)
        local retorno = 0

        for _ in pairs(obj) do
            retorno = retorno + 1
        end

        return retorno
    end

    function self.generateXML(namespace, element, path, kind, isInherited, namespaces)
        if not kind then kind = "element" end
        if not isInherited then isInherited = false end

        if not namespaces or namespaces == nil  then
            namespaces = {} 
            namespaces[namespace] = "ns1"
        end

        if not namespaces[namespace] then
            namespaces[namespace] = "ns"..tostring(self.getLength(namespaces) + 1)
        end

        local prefix = namespaces[namespace]
        local retorno = ""
        local isArray = false
        local needClose = false
        
        if element._attr then
            if element._attr.maxOccurs and not (element._attr.maxOccurs == "0") then
                local varName = path:match("[^.]+$")
                retorno = retorno.."{% for _, "..varName.." in pairs("..path..") do %}"
                path = varName
                isArray = true
            end
        end

        if kind == "element" then
            if not isInherited then
                if element._attr and not(element._attr.name == nil) then
                    if not path then path = element._attr.name else path = path.."."..element._attr.name end
                end

                retorno = retorno.."<"..prefix..":"..element._attr.name..">"
                needClose = true
            end
            
            if element._attr.type then
                if element._attr.type:startswith("xs:") then
                    retorno = retorno.."{{"..path.."}}"
                else
                    local ns, _type = self.getNamespace(element, element._attr.type)
                    local _xsd, _complexType = self.getElementByName(ns, _type, "complexType")

                    local namespaces, _xml = _xsd.generateXML(ns, _complexType, path, "complexType", isInherited, namespaces)
                    retorno = retorno.._xml
                end
            end
        elseif kind == "simpleType" then
            retorno = retorno.."{{"..path.."}}"
        elseif kind == "extension" then
            if element._attr.base then
                local nsBase, _typeBase = self.getNamespace(element, element._attr.base)
                local _xsd, el = self.getElementByName(nsBase, _typeBase)
                local namespaces, _xml = _xsd.generateXML(nsBase, el, path, "element", true, namespaces)
                retorno = retorno.._xml
            end
        end

        for attr in pairs(element) do
            if not (attr == "_attr") then
                local value = element[attr]

                if is_array(value) then
                    for _,item in pairs(value) do
                        local namespaces, _xml = self.generateXML(namespace, item, path, attr, nil, namespaces)
                        retorno = retorno.._xml
                    end
                else
                    local namespaces, _xml = self.generateXML(namespace, element[attr], path, attr, nil, namespaces)
                    retorno = retorno.._xml
                end
            end
        end

        if needClose then
            retorno = retorno.."</"..prefix..":"..element._attr.name..">"
        end
        
        if isArray then retorno = retorno.."{% end %}" end

        return namespaces, retorno
    end

    function self.generateRequest(namespace, elementType)
        local _xsd, element = self.getElementByName(namespace, elementType)
        
        if element then
            local request = "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
            local namespaces, _xml = _xsd.generateXML(namespace, element)
            
            for url, prefix in pairs(namespaces) do
                request = request.."xmlns:"..prefix.."=\""..url.."\" "
            end

            request = request.."><soapenv:Header/><soapenv:Body>"
            request = request.._xml
            request = request.."</soapenv:Body></soapenv:Envelope>"
            
            self.log(request)

            return request
        else
            error("type not found '"..elementType.."'")
        end

        return nil
    end

    function self.generateResponse(namespace, elementType)
        return "function (_body)\n\treturn _body\nend"
    end
    
    if schema then
        self.load(schema)
    end
    
    return self
end

return xsd2xml