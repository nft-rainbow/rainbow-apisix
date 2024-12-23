## 项目介绍
- apisix-go-plugin-runner: apisix go plugin
- apisix-docker: docker compose for apisix docker
- cleaner: clean `MongoDB` old data and log files

## cron jobs
```
0 0 * * * (cd /root/nft-rainbow/rainbow-apisix/cleaner && go run .)
0 0 * * * (cd /root/nft-rainbow/rainbow-apisix/apisix-docker && docker compose up --force-recreate &)
```

## 其它
更多内容请查看 `doc/README.md`
