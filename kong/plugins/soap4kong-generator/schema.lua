local typedefs = require "kong.db.schema.typedefs"
local validator = require "kong.plugins.soap4kong-generator.validator"

local plugin_name = ({...})[1]:match("^kong%.plugins%.([^%.]+)")

local schema = {
    name = plugin_name,
    fields = {
        { consumer = typedefs.no_consumer },  -- This plugin cannot be configured as a 'consumer'.
        { protocols = typedefs.protocols_http },
        { config = {
            type = "record",
            fields = {
                {
                    base_path = {
                        type = "string",
                        required = true,
                        custom_validator = validator.validate_base_path
                    }
                },
                {
                    endpoint = {
                        type = "string",
                        required = true,
                        custom_validator = validator.validate_endpoint
                    }
                },
                {
                    wsdl = {
                        type = "string",
                        required = true,
                        default = "?wsdl",
                        custom_validator = validator.validate_wsdl
                    }
                },
                {
                    operations = {
                        type = "array",
                        default = {},
                        elements = {
                            type = "string"
                        }
                    }
                }
                --[[
                ,{
                    params_type = {
                        type = "string",
                        one_of = { "Body", "Path", "Query", "*" },
                        default = "*"
                    }
                },
                {
                    operations_mapping = {
                        type = "array",
                        elements = {
                            type = "record",
                            fields = {
                                {
                                    path = {
                                        type = "string",
                                        required = true
                                    }
                                },
                                {
                                    method = {
                                        type = "string",
                                        required = true,
                                        one_of = { "GET", "POST", "DELETE", "PATCH", "PUT", "*" },
                                        default = "POST"
                                    }
                                },
                                {
                                    operation = {
                                        type = "string",
                                        required = true
                                    }
                                }
                            }
                        },
                    }
                }
]]
            },
            custom_validator = validator.validate,
        } },
    },
}

return schema
