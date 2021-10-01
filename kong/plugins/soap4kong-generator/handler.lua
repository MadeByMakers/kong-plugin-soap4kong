local BasePlugin = require "kong.plugins.base_plugin"

local soap4kongGenerator = BasePlugin:extend()

-- set the plugin priority, which determines plugin execution order (Default: 2001)
soap4kongGenerator.PRIORITY = 2001
soap4kongGenerator.VERSION = "0.1.2-1"

string.startswith = function(self, str)
    return self:find('^' .. str) ~= nil
end

string.endswith = function(self, str)
    return str == "" or self:sub(-#str) == str
end

string.split = function(self, str)
    local retorno = {}
    local index = 0
    for token in string.gmatch(self, "[^"..str.."]+") do
        retorno[index] = token
        index = index + 1
    end
    return retorno
end

string.escape = function(self)
	return self:gsub("[%(%)%.%%%+%-%*%?%[%^%$%]]", "%%%1")
end

return soap4kongGenerator