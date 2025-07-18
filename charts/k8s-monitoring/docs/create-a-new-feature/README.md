# Creating a New Feature

In the Kubernetes Monitoring Helm chart, features are stored as subcharts. This allows for the feature to be enabled
with a single flag, while keeping all the complexity of the feature inside its own values.yaml file and not the parent
chart's values.yaml file.

## Create chart and copy template files

Create a chart within the charts directory:

```shell
mkdir -p charts/feature-<feature-name>
cp -r docs/create-a-new-feature/new-feature-templates/* charts/feature-<feature-name>
```

Replace any of the following from the template files:

* `REPLACE_WITH_feature-name` - Replace with the feature name in this format: `node-logs`
* `REPLACE_WITH_feature_name` - Replace with the feature name in this format: `node_logs`
* `REPLACE_WITH_featureName` - Replace with the feature name in this format: `nodeLogs`
* `REPLACE_WITH_Feature Name` - Replace with the feature name in this format: `Node Logs`
* `REPLACE_WITH_SUPER_SHORT_DESCRIPTION` - A very short description, e.g. "gathering Node logs"
* `REPLACE_WITH_SHORT_DESCRIPTION` - A one-sentence description
* `REPLACE_WITH_LONG_DESCRIPTION` - A paragraph about the feature

## Update parent chart

* Add the feature in values.yaml:
    ```yaml
    # Requires a destination that supports REPLACE_WITH_DATA_TYPE.
    # To see the valid options, please see the [REPLACE_WITH_Feature Name feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-REPLACE_WITH_feature-name).
    # @default -- Disabled
    # @section -- Features - REPLACE_WITH_Feature Name
    nodeLogs:
      # -- Enable gathering REPLACE_WITH_Feature Name.
      # @section -- Features - REPLACE_WITH_Feature Name
      enabled: false
    
      # -- The destinations where REPLACE_WITH_DATA_TYPE will be sent. If empty, all REPLACE_WITH_DATA_TYPE-capable destinations will be used.
      # @section -- Features - REPLACE_WITH_Feature Name
      destinations: []
    
      # -- Which collector to assign this feature to. Do not change this unless you are sure of what you are doing.
      # @section -- Features - REPLACE_WITH_Feature Name
      # @ignored
      collector: REPLACE_WITH_DEFAULT_COLLECTOR
    
      # To see additional options, please see the [REPLACE_WITH_Feature Name feature documentation](https://github.com/grafana/k8s-monitoring-helm/tree/main/charts/k8s-monitoring/charts/feature-REPLACE_WITH_feature-name).
    ```
* Add the feature in Chart.yaml:
    ```yaml
  - alias: REPLACE_WITH_featureName
    name: feature-REPLACE_WITH_feature-name
    repository: ""
    version: 1.0.0
    condition: REPLACE_WITH_featureName.enabled
    ```
* Add to `features.list` in templates/features/_feature_helpers.tpl
* Create a feature file in templates/features/_feature_REPLACE_WITH_feature_name.tpl

## Fill out the feature-REPLACE_WITH_feature-name/templates/_module.alloy.tpl file

This is the template that will actually generate the Alloy module for your feature.

## Create examples and tests

Ideally, create an example in `docs/examples/` that shows how to use the feature, and add a test in `tests/integration`
that verifies the feature works as expected.

## Generate built-files

```shell
make clean build test
```
