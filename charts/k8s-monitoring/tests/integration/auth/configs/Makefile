htpasswd:
	htpasswd -c -B -b htpasswd basicuser basicpassword

passwords.yaml: htpasswd
	echo "---" > passwords.yaml
	kubectl create secret generic passwords --from-file=htpasswd -o yaml --dry-run=client >> passwords.yaml
