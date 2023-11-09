--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
local core = require("apisix.core")
local ngx  = ngx


local schema = {
  type = "object",
  properties = {},
  required = {},
}

local plugin_name = "scan-resp-rewrite"

-- 用于保存请求体的全局变量
local raw_response_body
local raw_status

local _M = {
  version = 0.1,
  priority = 0,
  name = plugin_name,
  schema = schema,
}

function _M.check_schema(conf)
  return core.schema.check(schema, conf)
end

function _M.header_filter(conf, ctx)
  core.log.warn("Response status in header_filter:", ngx.status)
  raw_status = ngx.status
  ngx.header.content_type = "application/json"

  if ngx.status >= 400 and ngx.status < 500 then
    ngx.status = 200                --修改状态码
    ngx.header.content_length = nil --置空，因为下面会修改 resp content
  end
end

-- 在body_filter阶段处理响应体
function _M.body_filter(conf, ctx)
  core.log.warn("Response status: ", ctx.var.status, ", Raw status: ", raw_status)

  if raw_status < 400 then
    return
  end

  raw_response_body = core.response.hold_body_chunk(ctx)
  if not ngx.arg[2] then
    return
  end

  core.log.warn("raw_response_body: ", raw_response_body)

  local body = {
    ["code"] = raw_status,
    ["data"] = raw_response_body,
  }
  core.log.warn("rewrited body", core.json.encode(body))
  ngx.arg[1] = core.json.encode(body)
end

return _M
