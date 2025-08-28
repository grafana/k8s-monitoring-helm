# ArgoCD

This test is working, but needs some investigation.

It seems to only work if I load the ArgoCD UI, edit the Application, and then sync it even without changes.

I'd like to ensure that it's reliable and automatable before enabling it by default.

## Running the test

Rename `disabled_test_plan.yaml` to `test_plan.yaml` and run:

```bash
export PATH=/path/to/grafana/helm-chart-toolbox/tools/helm-test:$PATH
helm-test
```
