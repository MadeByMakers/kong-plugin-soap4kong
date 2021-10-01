local fileUtil = require "kong.plugins.soap4kong-generator.fileUtil"
local xml2lua = require "xml2lua"
local handler = require "xmlhandler.tree"

local obj = {}

function obj:new(_wsdl, _basePath)
    local _obj = {}
    setmetatable(_obj, self)
    self.__index = self

    self.wsdl = _wsdl

    if self.wsdl:startswith("?") or self.wsdl:startswith("/") then
        self.wsdl = _basePath..self.wsdl
    end

    if not self.wsdl:startswith("<") then
        self.wsdl = fileUtil:downloadFile(self.wsdl)
    end

    self:load()

    return _obj
end


function obj:load()
    self.wsdl = fileUtil:cleanXML(self.wsdl)

    local wsdl_handler = handler:new()
    local parser = xml2lua.parser(wsdl_handler)
    parser:parse(self.wsdl)
    
    self.handler = wsdl_handler
end

function obj:getSOAPActions()
    local operations = {}
    local _index = 0

    for key, value in pairs(self.handler.root.definitions.portType.operation) do
        operations[_index] = value._attr.name
        _index = _index + 1
    end

    return operations
end

function obj:getSchema()
    return self.handler.root.definitions.types.schema
end

function obj:getInputType(operation)
    for _, value in pairs(self.handler.root.definitions.portType.operation) do
        if operation == value._attr.name then
            local _type = value.input._attr.message:split(":")[1]

            for __, value in pairs(self.handler.root.definitions.message) do
                if value._attr.name == _type then
                    local type_splited = value.part._attr.element:split(":")
                    local ns = self.handler.root.definitions._attr["xmlns:"..type_splited[0]]
                    return ns, type_splited[1]
                end
            end
        end
    end

    return nil, nil
end

function obj:getOutputType(operation)
    for _, value in pairs(self.handler.root.definitions.portType.operation) do
        if operation == value._attr.name then
            local _type = value.output._attr.message:split(":")[1]

            for __, value in pairs(self.handler.root.definitions.message) do
                if value._attr.name == _type then
                    local type_splited = value.part._attr.element:split(":")
                    local ns = self.handler.root.definitions._attr["xmlns:"..type_splited[0]]
                    return ns, type_splited[1]
                end
            end
        end
    end

    return nil, nil
end

return obj