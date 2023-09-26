local typedefs = require "kong.db.schema.typedefs"

return {
  name = "kong-splunk-handler",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    {
      config = {
        type = "record",
        fields = {
          { splunk_endpoint = typedefs.url({ required = true }) },
          { splunk_token = { type = "string", required = true }, },
          { splunk_index = { type = "string", required = true }, },
          { splunk_sourcetype = { type = "string", default = "AccessLog" }, }
        },
      },
    },
  },
}
