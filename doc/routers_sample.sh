#######################################################################################################
# Set your parameters
#######################################################################################################

# ******************* local **********************
# # local
env=local
## upstreams
upstream_proxy="172.16.100.252:8020"
upstream_logs_service="172.16.100.252:8000"
upstream_rainbow_app_service="172.16.100.252:8081"

# addrs
apisix_admin_addr=http://127.0.0.1:9180
rainbow_api_addr=http://172.16.100.252:8080
settle_addr=http://172.16.100.252:8091

## jwt keys
jwt_openapi_key=jwt-openapi-key
jwt_dashboard_key=jwt-dashboard-key

## domains
domain_server_rainbow_openapi=devapi.nftrainbow.me
domain_server_rainbow_dashboard=dev.nftrainbow.me
domain_server_rainbow_admin=devadmin.nftrainbow.me

domain_server_cmain_rpc=dev-rpc-cspace-main.nftrainbow.me
domain_server_ctest_rpc=dev-rpc-cspace-test.nftrainbow.me
domain_server_emain_rpc=dev-rpc-espace-main.nftrainbow.me
domain_server_etest_rpc=dev-rpc-espace-test.nftrainbow.me

domain_server_cmain_scan=dev-scan-cspace-main.nftrainbow.me
domain_server_ctest_scan=dev-scan-cspace-test.nftrainbow.me
domain_server_emain_scan=dev-scan-espace-main.nftrainbow.me
domain_server_etest_scan=dev-scan-espace-test.nftrainbow.me

## apikey
apikey_confura_main="xxx"
apikey_confura_test="xxx"
apikey_scan_main_cspace="xxx"
apikey_scan_main_espace="xxx"
apikey_scan_test_cspace="xxx"
apikey_scan_test_espace="xxx"

# # ******************* dev **********************
# env=dev

# ## upstreams
# upstream_proxy="172.18.0.1:8020"
# upstream_logs_service="172.18.0.1:19080"
# upstream_rainbow_app_service="172.18.0.1:8081"

# ## addrs
# apisix_admin_addr=http://dev-apisix-admin.nftrainbow.cn
# rainbow_api_addr=http://127.0.0.1:8080
# settle_addr=http://127.0.0.1:8091

# ## jwt keys
# jwt_openapi_key=jwt-openapi-key
# jwt_dashboard_key=jwt-dashboard-key

# ## domains
# domain_server_rainbow_openapi=devapi.nftrainbow.cn
# domain_server_rainbow_dashboard=dev.nftrainbow.cn
# domain_server_rainbow_admin=devadmin.nftrainbow.cn

# domain_server_cmain_rpc=dev-rpc-cspace-main.nftrainbow.cn
# domain_server_ctest_rpc=dev-rpc-cspace-test.nftrainbow.cn
# domain_server_emain_rpc=dev-rpc-espace-main.nftrainbow.cn
# domain_server_etest_rpc=dev-rpc-espace-test.nftrainbow.cn

# domain_server_cmain_scan=dev-scan-cspace-main.nftrainbow.cn
# domain_server_ctest_scan=dev-scan-cspace-test.nftrainbow.cn
# domain_server_emain_scan=dev-scan-espace-main.nftrainbow.cn
# domain_server_etest_scan=dev-scan-espace-test.nftrainbow.cn

# ## apikeys
# apikey_confura_main="0rW8CEuqNvDaWNybiukVXK5kJp9GP3rdptimpqxu9bdc"
# apikey_confura_test="xxx"
# apikey_scan_main_cspace="xxx"
# apikey_scan_main_espace="xxx"
# apikey_scan_test_cspace="xxx"
# apikey_scan_test_espace="xxx"

# # ******************* prod **********************
# env=prod

# ## upstreams
# upstream_proxy="172.18.0.1:8020"
# upstream_logs_service="172.18.0.1:19080"
# upstream_rainbow_app_service="172.16.0.110:8090" #测试使用8091, 正式上线改为8090

# ## addrs
# apisix_admin_addr=http://127.0.0.1:9180
# rainbow_api_addr=http://172.16.0.110:8080 #测试使用8083, 正式上线改为8080
# settle_addr=http://172.16.0.110:8031

# ## jwt keys
# jwt_openapi_key=jwt-openapi-zxcv
# jwt_dashboard_key=jwt-dashboard-asdf

# ## domains
# domain_server_rainbow_openapi=api.nftrainbow.cn # 测试使用 cmain-rpc.nftrainbow.cn， 正式上线改为 api.nftrainbow.cn
# domain_server_rainbow_dashboard=console.nftrainbow.cn #测试使用 admin.nftrainbow.cn，正式上线改为 console.nftrainbow.cn
# domain_server_rainbow_admin=admin.nftrainbow.cn #正式上线改为 admin.nftrainbow.cn

# domain_server_cmain_rpc=cmain-rpc.nftrainbow.cn #正式上线改为 cmain-rpc.nftrainbow.cn
# domain_server_ctest_rpc=ctest-rpc.nftrainbow.cn
# domain_server_emain_rpc=emain-rpc.nftrainbow.cn
# domain_server_etest_rpc=etest-rpc.nftrainbow.cn

# domain_server_cmain_scan=cmain-scan.nftrainbow.cn
# domain_server_ctest_scan=ctest-scan.nftrainbow.cn
# domain_server_emain_scan=emain-scan.nftrainbow.cn
# domain_server_etest_scan=etest-scan.nftrainbow.cn

# ## apikeys
# apikey_confura_main="0rW8CEuqNvDaWNybiukVXK5kJp9GP3rdptimpqxu9bdc"
# apikey_confura_test="xxx"
# apikey_scan_main_cspace="xxx"
# apikey_scan_main_espace="xxx"
# apikey_scan_test_cspace="xxx"
# apikey_scan_test_espace="xxx"

echo "开始配置apisix路由"

#######################################################################################################

# *** response rewrite 模版
response_template_scan=$(
  cat <<EOF | awk '{gsub(/"/,"\\\"");};1' | awk '{$1=$1};1' | tr -d '\r\n' dayong@dayongdeMBP
{% if (_ctx.var.status ~= 200) then %} {"code":{{_ctx.var.status}},"data":{*_body*}} {% else %} {*_body*} {% end %}
EOF
)

# ******************** rainbow 使用的upstream *******************

# 添加upstream
curl $apisix_admin_addr/apisix/admin/upstreams/100 \
  -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -i -X PUT -d '
{
    "type":"roundrobin",
    "nodes":{
        "'${upstream_proxy}'": 1
    }
}'

curl $apisix_admin_addr/apisix/admin/upstreams/200 \
  -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -i -X PUT -d '
{
    "type":"roundrobin",
    "nodes":{
        "'${upstream_rainbow_app_service}'": 1
    }
}'

curl $apisix_admin_addr/apisix/admin/upstreams/300 \
  -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -i -X PUT -d '
{
    "type":"roundrobin",
    "nodes":{
        "'${upstream_logs_service}'": 1
    }
}'

# 查upstream
curl $apisix_admin_addr/apisix/admin/upstreams -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1'

# ******************** 添加全局plugin *******************

# rsp_template='$({"raw_body":"{{_body}}"})'
# echo $rsp_template

curl $apisix_admin_addr/apisix/admin/global_rules/1 -X PUT \
  -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' \
  -d '{
        "plugins": {
            "prometheus": {
              "prefer_name": false
            }
        }
     }'

# "hello":{
#   "body": "hello world"
# },

# exit

# ******************** rainbow 使用的路由 *******************

# rainbow open api
curl $apisix_admin_addr/apisix/admin/routes/1000 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-openapi",
  "desc": "rainbow open api 路由，只匹配openapi需要收费的api",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/v1/(accounts|mints|transfers|burns|contracts|metadata|files|nft|tx).*$"]
  ],
  "host": "'${domain_server_rainbow_openapi}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "conf": [
         {"name":"jwt-auth", "value":"{\"token_lookup\":\"header: Authorization\",\"jwt_key\":\"'${jwt_openapi_key}'\"}"},
         {"name":"rainbow-api-parser", "value":"{}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"request\"}"}
       ]
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "'${rainbow_api_addr}'"
      }
    },
    "ext-plugin-post-resp": {
      "conf": [
         {"name":"count","value":"{}"}
      ]
    },
    "response-rewrite": {
      "headers": {
          "set": {
              "Content-Type": "application/json"
          }
      }
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_open_api"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# exit 0

# TODO: rainbow api dashboard 收费相关接口
curl $apisix_admin_addr/apisix/admin/routes/1100 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-dashboard-api",
  "desc": "rainbow dashboard api 路由,只匹配dashboard需要收费的api",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/dashboard/apps/.*/(contracts|nft).*$"]
  ],
  "host": "'${domain_server_rainbow_dashboard}'",
  "methods": ["POST"],
  "plugins": {
    "ext-plugin-pre-req": {
       "conf": [
         {"name":"jwt-auth", "value":"{\"token_lookup\":\"header: Authorization\",\"jwt_key\":\"'${jwt_dashboard_key}'\"}"},
         {"name":"rainbow-api-parser", "value":"{}"},
         {"name":"count", "value":"{}"}
       ]
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "'${rainbow_api_addr}'"
      }
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"count","value":"{}"}
       ]
    },
    "response-rewrite": {
      "headers": {
          "set": {
              "Content-Type": "application/json"
          }
      }
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_dashboard"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# rainbow api dashboard 不需要身份验证的接口
# dashboardRouter.POST("/register", userRegisterEndpoint)
# dashboardRouter.POST("/login", middlewares.UserLoginHandler)
# dashboardRouter.POST("/logout", middlewares.JwtAuthMiddleware.LogoutHandler)
# dashboardRouter.GET("/refresh_token", middlewares.UserRefreshTokenHandler)
# dashboardRouter.POST("/password/session", createPasswordResetSessionEndpoint)
# dashboardRouter.GET("/password/session/:code", getPasswordResetSessionEndpoint)
# dashboardRouter.POST("/password/session/:code", newPasswordEndpoint)
curl $apisix_admin_addr/apisix/admin/routes/1115 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-dashboard-api-no-jwt",
  "desc": "rainbow dashboard api 不需要身份验证的接口",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/dashboard/(register|login|logout|refresh_token|password).*$"]
  ],
  "host": "'${domain_server_rainbow_dashboard}'",
  "plugins": {
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "'${rainbow_api_addr}'"
      }
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_dashboard"
    }
  },
  "upstream_id": "100",
  "priority": 300
}'

# rainbow api dashboard 免费接口，但需要身份验证
curl $apisix_admin_addr/apisix/admin/routes/1120 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-dashboard-api-free",
  "desc": "rainbow dashboard api 路由,只匹配dashboard免费api",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/dashboard/.*$"]
  ],
  "host": "'${domain_server_rainbow_dashboard}'",
  "methods": ["POST"],
  "plugins": {
    "ext-plugin-pre-req": {
       "conf": [
          {"name":"jwt-auth", "value":"{\"token_lookup\":\"header: Authorization\",\"jwt_key\":\"'${jwt_dashboard_key}'\"}"}
       ]
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "'${rainbow_api_addr}'"
      }
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_dashboard"
    }
  },
  "upstream_id": "100",
  "priority": 200
}'

# rainbow apps , NOTE: 目前 raibnow-app-service 没有走apisix，直接域名console.nftraibnow.cn 通过nginx proxy_pass 到它，所以这个router暂时没有用到
curl $apisix_admin_addr/apisix/admin/routes/1130 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-app-service",
  "desc": "rainbow-app-service 路由",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/apps/.*$"]
  ],
  "host": "'${domain_server_rainbow_dashboard}'",
  "plugins": {
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_app_service"
    }
  },
  "upstream_id": "200",
  "priority": 400
}'

# rainbow logs
curl $apisix_admin_addr/apisix/admin/routes/1140 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-http-logs",
  "desc": "rainbow-http-logs 路由",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/logs/.*$"]
  ],
  "host": "'${domain_server_rainbow_dashboard}'",
  "upstream_id": "300",
  "priority": 400
}'

# settle 服务
curl $apisix_admin_addr/apisix/admin/routes/1150 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-settle",
  "desc": "rainbow settle",
  "uri": "/*",
  "vars": [
    ["uri", "~~", "^/settle/.*$"]
  ],
  "host": "'${domain_server_rainbow_dashboard}'",
  "plugins": {
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "'${settle_addr}'"
      }
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_settle"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# rainbow api 其它所有接口，包括 v1其它,swagger,debug,dashboard,settle,admin
curl $apisix_admin_addr/apisix/admin/routes/1200 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rainbow-api-normal",
  "desc": "rainbow api 基础路由，优先级最低，用于免费接口",
  "uri": "/*",
  "hosts": ["'${domain_server_rainbow_openapi}'","'${domain_server_rainbow_dashboard}'","'${domain_server_rainbow_admin}'"],
  "plugins": {
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "'${rainbow_api_addr}'"
      }
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/rainbow_api"
    }
  },
  "upstream_id": "100",
  "priority": 0
}'

# ******************** confura 路由 ********************
# cspace-main
curl $apisix_admin_addr/apisix/admin/routes/2000 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rpc-cspace-main",
  "desc": "confura core space main net",
  "uri": "/*",
  "host": "'${domain_server_cmain_rpc}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"path\"}"},
         {"name":"confura-parser", "value":"{\"is_mainnet\":true,\"is_cspace\":true}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "confura-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Url": "https://main.confluxrpc.com/'${apikey_confura_main}'"
      }
    },
    "response-rewrite": {
      "headers": {
          "remove": ["Access-Control-Allow-Origin"]
      },
      "vars":[
          [ "status","==",200 ]
      ]
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"rpc-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/confura_cspace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# cspace-test
curl $apisix_admin_addr/apisix/admin/routes/2100 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rpc-cspace-test",
  "desc": "confura core space test net",
  "uri": "/*",
  "host": "'${domain_server_ctest_rpc}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"path\"}"},
         {"name":"confura-parser", "value":"{\"is_mainnet\":false,\"is_cspace\":true}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "confura-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Url": "https://test.confluxrpc.com/'${apikey_confura_test}'"
      }
    },
    "response-rewrite": {
      "headers": {
          "remove": ["Access-Control-Allow-Origin"]
      },
      "vars":[
          [ "status","==",200 ]
      ]
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"rpc-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/confura_cspace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# espace-main
curl $apisix_admin_addr/apisix/admin/routes/2200 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rpc-espace-main",
  "desc": "confura espace mainnet",
  "uri": "/*",
  "host": "'${domain_server_emain_rpc}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"path\"}"},
         {"name":"confura-parser", "value":"{\"is_mainnet\":true,\"is_cspace\":false}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "confura-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Url": "https://evm.confluxrpc.com/'${apikey_confura_main}'"
      }
    },
    "response-rewrite": {
      "headers": {
          "remove": ["Access-Control-Allow-Origin"]
      },
      "vars":[
          [ "status","==",200 ]
      ]
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"rpc-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/confura_espace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# espace-test
curl $apisix_admin_addr/apisix/admin/routes/2300 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "rpc-espace-test",
  "desc": "confura espace testnet",
  "uri": "/*",
  "host": "'${domain_server_etest_rpc}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"path\"}"},
         {"name":"confura-parser", "value":"{\"is_mainnet\":false,\"is_cspace\":false}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "confura-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Url": "https://evmtestnet.confluxrpc.com/'${apikey_confura_test}'"
      }
    },
    "response-rewrite": {
      "headers": {
          "remove": ["Access-Control-Allow-Origin"]
      },
      "vars":[
          [ "status","==",200 ]
      ]
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"rpc-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/confura_espace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# Scan
# cspace-main
curl $apisix_admin_addr/apisix/admin/routes/3000 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "scan-cspace-main",
  "desc": "scan core space main net",
  "uri": "/*",
  "host": "'${domain_server_cmain_scan}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"header\"}"},
         {"name":"scan-parser", "value":"{\"is_mainnet\":true,\"is_cspace\":true}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "scan-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "https://api.confluxscan.net",
        "X-Rainbow-Append-Query": "'apiKey=${apikey_scan_main_cspace}'",
        "apiKey": "'${apikey_scan_main_cspace}'"
      }
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"scan-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/scan_cspace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# cspace-test
curl $apisix_admin_addr/apisix/admin/routes/3100 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "scan-cspace-test",
  "desc": "scan core space test net",
  "uri": "/*",
  "host": "'${domain_server_ctest_scan}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"header\"}"},
         {"name":"scan-parser", "value":"{\"is_mainnet\":false,\"is_cspace\":true}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "scan-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "https://api-testnet.confluxscan.net",
        "X-Rainbow-Append-Query": "'apiKey=${apikey_scan_test_cspace}'",
        "apiKey": "'${apikey_scan_test_cspace}'"
      }
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"scan-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/scan_cspace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# espace-main
curl $apisix_admin_addr/apisix/admin/routes/3200 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "scan-espace-main",
  "desc": "scan espace main net",
  "uri": "/*",
  "host": "'${domain_server_emain_scan}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"header\"}"},
         {"name":"scan-parser", "value":"{\"is_mainnet\":true,\"is_cspace\":false}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "scan-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "https://evmapi.confluxscan.net",
        "X-Rainbow-Append-Query": "'apiKey=${apikey_scan_main_espace}'",
        "apiKey": "'${apikey_scan_main_espace}'"
      }
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"scan-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/scan_espace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

# espace-test
curl $apisix_admin_addr/apisix/admin/routes/3300 -H 'X-API-KEY: edd1c9f034335f136f87ad84b625c8f1' -X PUT -d '
{
  "name": "scan-espace-test",
  "desc": "scan espace test net",
  "uri": "/*",
  "host": "'${domain_server_etest_scan}'",
  "plugins": {
    "ext-plugin-pre-req": {
       "_meta": {
         "priority": -10000
       },
       "conf": [
         {"name":"apikey-auth", "value":"{\"lookup\":\"header\"}"},
         {"name":"scan-parser", "value":"{\"is_mainnet\":false,\"is_cspace\":false}"},
         {"name":"count", "value":"{}"},
         {"name":"rate-limit", "value":"{\"mode\":\"cost_type\"}"}
       ]
    },
    "scan-resp-rewrite": {
    },
    "proxy-rewrite": {
      "headers": {
        "X-Rainbow-Target-Addr": "https://evmapi-testnet.confluxscan.net",
        "X-Rainbow-Append-Query": "'apiKey=${apikey_scan_test_espace}'",
        "apiKey": "'${apikey_scan_test_espace}'"
      }
    },
    "ext-plugin-post-resp": {
       "conf": [
         {"name":"scan-resp-handler","value":"{}"}
       ]
    },
    "http-logger": {
      "_meta": {
        "disable": false
      },
      "include_req_body": true,
      "include_resp_body": true,
      "uri": "http://'${upstream_logs_service}'/logs/scan_espace"
    }
  },
  "upstream_id": "100",
  "priority": 400
}'

echo "配置apisix路由完成"
