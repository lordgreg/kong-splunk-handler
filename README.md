# Kong Splunk Handler
---

## Description

This is a Kong 3.x Splunk plugin, which enables you to send specific information to the Splunk server.

Splunk specifics, such as `index` and `source type` **are** supported.

## Parameters

| Field name | Required | Default value | Description |
| - | - | - | - |
| splunk_endpoint   | Yes | - | Endpoint to your Splunk
| splunk_token      | Yes | - | Access Token
| splunk_index      | Yes | - | Index for Splunk
| splunk_sourcetype | No  | `AccessLog` | Source type, if different

## How to use

Simply configure your service like that:

```yml
_format_version: "3.0"
services:

- name: anything-test
  path: /anything
  host: httpbin.org
  enabled: true
  port: 80
  protocol: http
  routes:
  - name: anything-test-route
    paths:
    - /anything-test
    protocols:
    - http
    - https
    strip_path: true
    preserve_host: false
    regex_priority: 0
    request_buffering: true
    response_buffering: true
    https_redirect_status_code: 426
  plugins:
  - name: kong-splunk-handler
    config:
      splunk_endpoint: "https://YOUR_SERVER/services/collector"
      splunk_token: "SPLUNK_TOKEN"
      splunk_sourcetype: "AccessLog"
      splunk_index: "SPLUNK_INDEX"

```

## Support

If you have any issues, be sure to check if you have the latest version.

In case of problems, be sure to visit the [issues](https://github.com/lordgreg/kong-splunk-handler/issues) site.

You can also request new features, however, pull request are something you can do too. ;)


## Contributors

[![](https://github.com/lordgreg.png?size=50)](https://github.com/lordgreg)