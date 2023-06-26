charts/kubernetes-monitoring/README.md: charts/kubernetes-monitoring/README.md.gotmpl
	helm-docs --template-files charts/kubernetes-monitoring/README.md.gotmpl --chart-search-root charts/kubernetes-monitoring

README.md: charts/kubernetes-monitoring/README.md
	cp charts/kubernetes-monitoring/README.md README.md
