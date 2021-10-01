local typedefs = require "kong.db.schema.typedefs"

local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

string.startswith = function(self, str)
    return self:find('^' .. str) ~= nil
end

local function validate_variable(value)
    local _, err = load("local var = "..value)
    if err then
      return false, "error parsing " .. plugin_name .. ": " .. err
    end
    return true
end

local schema = {
    name = plugin_name,
    fields = {
        { consumer = typedefs.no_consumer },  -- This plugin cannot be configured as a 'consumer'.
        { protocols = typedefs.protocols_http },
        { config = {
            type = "record",
            fields = {
                {
                    service = {
                        type = "record",
                        fields = {
                            {
                                endpoint = {
                                    type = "string",
                                    required = true
                                }
                            },
                            {
                                operation = {
                                    type = "string",
                                    required = true,
                                }
                            },
                        }
                    },
                },
                {
                    mapping = {
                        type = "record",
                        fields = {
                            {
                                request = {
                                    type = "string",
                                    required = true
                                },
                            },
                            {
                                response = {
                                    type = "string",
                                    required = true,
                                    custom_validator = validate_variable
                                }
                            }
                        }
                    }
                }
            },
        } },
    },
}

return schema