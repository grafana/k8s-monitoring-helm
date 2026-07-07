# preset values

```shell
helm upgrade --install grafana-cloud \
  --namespace default --create-namespace \
  grafana/k8s-monitoring \
  --set "cluster.name=my-cluster" \
  --set "collectorCommon.alloy.remoteConfig.url=https://fleet-management-dev-003.grafana-dev.net" \
  --set "collectorCommon.alloy.remoteConfig.auth.username=11225" \
  --set "collectorCommon.alloy.remoteConfig.auth.password=fsafsa" \
  --values - <<'EOF'
<THE VALUES CONTENT GOES HERE>
EOF
```
