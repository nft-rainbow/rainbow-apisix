# Projects
- apisix-go-plugin-runner: apisix go plugin
- apisix-docker: docker compose for apisix docker
- cleaner: clean `MongoDB` old data and log files

# cron jobs
```
0 0 * * * (cd /root/nft-rainbow/rainbow-apisix/cleaner && go run .)
0 0 * * * (cd /root/nft-rainbow/rainbow-apisix/apisix-docker && docker compose up --force-recreate &)
```