.PHONY: clean
clean:
	rm -f dependencies/passwords.yaml

HAS_HTPASSWD := $(shell command -v htpasswd;)
dependencies/passwords.yaml:
	echo "---" > $@
ifdef HAS_HTPASSWD
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell htpasswd -nbB basicuser basicpassword)' -o yaml --dry-run=client >> $@
else
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell docker run --platform linux/amd64 --rm xmartlabs/htpasswd basicuser basicpassword)' -o yaml --dry-run=client >> $@
endif

.PHONY: all
all: dependencies/passwords.yaml
