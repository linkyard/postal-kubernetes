# Postal on kubernetes

A docker-image and helm-chart to deploy [Postal](https://postal.atech.media/) on kubernetes.

Please refer to the individual documentation for the docker-image and the helm-chart:

- [docker-image](docker/README.md)
- [helm-chart](helm/postal/README.md)

Getting the Docker image and helm chart:

- The docker-image is available on Docker Hub: [linkyard/postal](https://hub.docker.com/r/linkyard/postal/)
- The helm chart is available at [charts.linkyard.ch](https://charts.linkyard.ch)

## Roadmap

- Contribute our little fixes to upstream
- Add the ability to start individual Portal processes for easier HA setups and scaling
- Add meaningful readiness and liveness probes
