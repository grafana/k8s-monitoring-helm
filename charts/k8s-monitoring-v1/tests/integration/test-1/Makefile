deployments/secretgen-controller.yaml:
	curl -L -o deployments/secretgen-controller.yaml https://github.com/carvel-dev/secretgen-controller/releases/latest/download/release.yml

.PHONY: clean
clean:
	rm -f deployments/secretgen-controller.yaml

.PHONY: all
all: deployments/secretgen-controller.yaml
