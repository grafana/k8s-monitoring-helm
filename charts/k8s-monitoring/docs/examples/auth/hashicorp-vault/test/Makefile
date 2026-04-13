.PHONY: clean
clean:
	rm -f dependencies/passwords.yaml

HAS_HTPASSWD := $(shell command -v htpasswd;)
dependencies/passwords.yaml:
	echo "---" > $@
ifdef HAS_HTPASSWD
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell htpasswd -nbB promuser prompassword)$(shell printf "\n")$(shell htpasswd -nbB lokiuser lokipassword)' -o yaml --dry-run=client >> $@
else
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell docker run --platform linux/amd64 --rm xmartlabs/htpasswd promuser prompassword)$(shell printf "\n")$(shell docker run --platform linux/amd64 --rm xmartlabs/htpasswd lokiuser lokipassword)' -o yaml --dry-run=client >> $@
endif

.PHONY: all
all: dependencies/passwords.yaml
