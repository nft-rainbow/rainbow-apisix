build-plugin:
	cd ./apisix-go-plugin-runner && \
	make build-linux && \
	mv ./go-runner ../apisix-docker/apisix_conf/apisix-go-plugin-runner/

deploy:
	make build-plugin && \
	cd apisix-docker && \
	DEBUG=${DEBUG} docker compose up --force-recreate -d
