deployments/passwords.yaml:
	echo "---" > deployments/passwords.yaml
	kubectl create secret generic passwords --from-literal=htpasswd='$(shell htpasswd -nb -B basicuser basicpassword)' -o yaml --dry-run=client >> deployments/passwords.yaml
