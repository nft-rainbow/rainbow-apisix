build-plugin:
	cd ./apisix-go-plugin-runner && \
	make build-linux && \
	mv ./go-runner ../apisix-docker/apisix_conf/apisix-go-plugin-runner/ && \
	cp ./cmd/go-runner/plugins/config.yaml ../apisix-docker/apisix_conf/apisix-go-plugin-runner/

deploy:
	make build-plugin && \
	cd apisix-docker && \
	docker compose up --force-recreate -d