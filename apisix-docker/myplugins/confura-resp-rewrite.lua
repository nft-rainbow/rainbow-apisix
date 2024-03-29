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

local plugin_name = "confura-resp-rewrite"

-- 用于保存请求体的全局变量
local request_body
local raw_response_body
local raw_status

local _M = {
  version = 0.1,
  priority = 1008,
  name = plugin_name,
  schema = schema,
}


function _M.check_schema(conf)
  return true
  -- return core.schema.check(schema, conf)
end

-- ISSUE: 该阶段在配置了插件ext-plugin-pre-req后则不执行，原因未知
function _M.access(conf, ctx)
  core.log.warn("Run access")
  request_body = core.request.get_body(1024 * 1000, ctx)
end

-- NOTICE: 该阶段在配置了插件ext-plugin-pre-req且设置它的优先级为-10000则会执行
function _M.rewrite(conf, ctx)
  request_body = core.request.get_body(1024 * 1000, ctx)
  core.log.warn("Run rewrite")
end

function _M.header_filter(conf, ctx)
  core.log.warn("Response status in header_filter:", ngx.status)
  raw_status = ngx.status
  ngx.header.content_type = "application/json"

  if ngx.status >= 400 then -- and ngx.status < 500 then
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

  core.log.warn("Request body: <" .. request_body .. ">", " raw_response_body: ", raw_response_body)
  local decoded = core.json.decode(request_body)

  if core.table.isarray(decoded) then
    core.log.warn("is array")
    local body = {}
    for key, value in pairs(decoded) do
      body[key] = {
        ["jsonrpc"] = value.jsonrpc,
        ["id"] = value.id,
        ["error"] = {
          ["code"] = -32002,
          ["message"] = raw_response_body,
          ["data"] = "upstream status: " .. raw_status,
        }
      }
    end
    ngx.arg[1] = core.json.encode(body)
  else
    core.log.warn("is single")
    local body = {
      ["jsonrpc"] = decoded.jsonrpc,
      ["id"] = decoded.id,
      ["error"] = {
        ["code"] = -32002,
        ["message"] = raw_response_body,
        ["data"] = "upstream status: " .. raw_status,
      }
    }
    core.log.warn("rewrited body", core.json.encode(body))
    ngx.arg[1] = core.json.encode(body)

    -- ngx.arg[1] = "hello world"
  end




  -- ngx.log(ngx.ERR, "Request body by ctx", core.request.get_body(1024 * 1000, ctx))
  -- core.log.warn(core.json.encode(ctx, true))

  -- 获取保存的请求体并打印到Nginx的错误日志中
  -- ngx.log(ngx.ERR, "Request Body: ", request_body)

  -- 返回响应体
  -- ngx.arg[1] = request_body
end

return _M
