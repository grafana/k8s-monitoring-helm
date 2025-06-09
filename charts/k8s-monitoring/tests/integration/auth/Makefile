.PHONY: check
check: ;

.PHONY: clean
clean:
	rm -f deployments/passwords.yaml

HAS_HTPASSWD := $(shell command -v htpasswdxxxxx;)
deployments/passwords.yaml:
	echo "---" > deployments/passwords.yaml
ifdef HAS_HTPASSWD
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell htpasswd -nbB basicuser basicpassword)' -o yaml --dry-run=client >> deployments/passwords.yaml
else
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell docker run --platform linux/amd64 --rm xmartlabs/htpasswd basicuser basicpassword)' -o yaml --dry-run=client >> deployments/passwords.yaml
endif

.PHONY: all
all: deployments/passwords.yaml

.PHONY: run-test
run-test:
	../../../../../../scripts/run-cluster-test.sh .
