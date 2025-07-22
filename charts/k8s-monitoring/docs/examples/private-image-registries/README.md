# Private Image Registries

There are two methods for overriding the image registries for the container images loaded by this Helm chart:

*   [Global Private Image Registries](globally) will set the image registry for all images with a minimal amount of configuration. This is recommended if all images are present in the same image priavate registry.
*   [Individual Private Image Registries](individual) will set the image registry for each image reference individually. This is recommended if you want to replace a subset of images and want to chose them individaully, or if you need different image registries for different upstream registries (i.e. one proxy registry for Docker Hub, another for ghcr.io).
