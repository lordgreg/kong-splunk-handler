local http = require "resty.http"
local Queue = require "kong.tools.queue"
local cjson = require "cjson"
local cjson_encode = cjson.encode
local fmt = string.format

local KongSplunkHandler = {}

KongSplunkHandler.PRIORITY = 12
KongSplunkHandler.VERSION = "1.0.0"

local function splunk_event(config, ngx)
  return {
    index = config.splunk_index,
    sourcetype = config.splunk_sourcetype,
    event = {
      severity = "INFO",
      logger = "Kong Splunk Handler",
      message = "KongTestLog",
      url = ngx.var.request_uri,
      method = ngx.var.request_method,
      client_ip = ngx.var.remote_addr,
      host = ngx.var.host,
      upstream_host = ngx.var.upstream_host,
      upstream_uri = ngx.var.upstream_uri,
      upstream_status = ngx.var.upstream_status,
      upstream_response_time = ngx.var.upstream_response_time,
      request_time = ngx.var.request_time,
      response_size = ngx.var.bytes_sent,
      response_status = ngx.var.status,
      request_size = ngx.var.request_length,
      request_id = ngx.var.request_id,
      request_uri = ngx.var.request_uri,
      request_uri_args = ngx.var.args,
      request_uri_scheme = ngx.var.scheme,
      request_uri_host = ngx.var.host,
      request_uri_port = ngx.var.server_port,
      request_uri_path = ngx.var.uri,
      request_uri_query = ngx.var.query_string,
      request_uri_fragment = ngx.var.fragment,
      request_uri_username = ngx.var.remote_user
    }
  }
end

local function prepare_payload(config, entries)
  local string_entries = ""

  ---@diagnostic disable-next-line: unused-local
  for k, v in pairs(entries)
  do
    local string_entry = cjson_encode(v)
    string_entries = string_entries .. string_entry
  end

  return string_entries
end

local function send_request(config, entries)
  kong.log.debug("KongTestLog Sending data to Splunk");

  local payload = prepare_payload(config, entries)

  local httpc = http.new()

  local res, err = httpc:request_uri(config.splunk_endpoint, {
    method = "POST",
    body = payload,
    headers = {
      ["Content-Type"] = "application/json",
      ["Authorization"] = "Splunk " .. config.splunk_token,
    },
  })
  if not res then
    return nil, ngx.ERR .. "request failed: " .. err
  end

  local json_body = cjson.decode(res.body)

  if json_body.code == 0 then
    kong.log.debug("KongTestLog Success = ", cjson_encode(json_body.code));
  else
    return nil, "KongTestLog Error = " .. cjson_encode(json_body.code);
  end

  return true
end

function KongSplunkHandler:log(config)
  local queue_config =                                                                             -- configuration for the queue itself (defaults shown unless noted)
  {
    name = fmt("%s:%s:%s", config.splunk_endpoint, config.splunk_index, config.splunk_sourcetype), -- name of the queue (required)
    log_tag = "kong-splunk-handler plugin " .. kong.plugin.get_id(),                                         -- tag string to identify plugin or application area in logs
    max_batch_size = 10,                                                                           -- maximum number of entries in one batch (default 1)
    max_coalescing_delay = 1,                                                                      -- maximum number of seconds after first entry before a batch is sent
    max_entries = 10,                                                                              -- maximum number of entries on the queue (default 10000)
    -- max_bytes = 100,            -- maximum number of bytes on the queue (default nil)
    initial_retry_delay = 0.01,                                                                    -- initial delay when retrying a failed batch, doubled for each subsequent retry
    max_retry_time = 60,                                                                           -- maximum number of seconds before a failed batch is dropped
    max_retry_delay = 60,                                                                          -- maximum delay between send attempts, caps exponential retry
  }

  local ok, err = Queue.enqueue(
    queue_config,
    send_request,
    config,
    splunk_event(config, ngx)
  )
  if not ok then
    kong.log.err("Error setting up queue ", err)
  end
end

return KongSplunkHandler
