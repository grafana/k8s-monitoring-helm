htpasswd:
	htpasswd -c -B -b htpasswd promuser prompassword
	htpasswd -B -b htpasswd oteluser otelpassword

passwords.yaml: htpasswd
	echo "---" > passwords.yaml
	kubectl create secret generic passwords --from-file=htpasswd -o yaml --dry-run=client >> passwords.yaml
