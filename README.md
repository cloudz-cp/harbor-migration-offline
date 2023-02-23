#  Container-images/Helm-chart's exporter/importer for Harbor

## Prerequisite
* [curl](https://curl.se/download.html) (7.85.0)
* [jq](https://stedolan.github.io/jq/download) (1.6)
* [skopeo](https://github.com/containers/skopeo/releases) (1.10.0)
* [helm](https://github.com/helm/helm/releases) (v3.10.3)
* [helm cm-plugin](https://github.com/chartmuseum/helm-push/releases/tag/v0.10.3) (v0.10.3)


```shell
git clone https://github.com/cloudz-cp/harbor-migration-offline.git
```


## Export Harbor project's container images

```shell
cd container-images
# check variables for Harbor domain and credentials
vi export-imgs.sh
chmod +x export-imgs.sh
./export-imgs.sh
```

## Import Harbor project's container images

```shell
cd container-images
# check variables for Harbor domain and credentials
vi import-imgs.sh
chmod +x import-imgs.sh
./import-imgs.sh
```

## Export Harbor project's helm-charts

```shell
cd helm-charts
# check variables for Harbor domain and credentials
vi export-charts.sh
chmod +x export-charts.sh
./export-charts.sh
```

## Import Harbor project's helm-charts

1. Login Harbor
2. Create Projects named 'cloudzcp', 'cloudzcp-addon', 'cloudzcp-public'
3. Click each project
4. Click 'Helm Charts' tab
5. Click 'Upload' button
6. Click 'Browse' button and select chart-archive file