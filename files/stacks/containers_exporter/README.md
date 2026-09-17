# Containers Exporter

A Prometheus exporter that collects metrics about Docker containers. The exporter is written in Python and uses the Docker SDK to interact with the Docker API.

The exporter exposes the following metrics:

docker_containers_total: Total number of Docker containers
docker_containers_running_total: Number of running Docker containers
docker_containers_stopped_total: Number of stopped Docker containers
docker_containers_other_total: Number of Docker containers in other states (not running or stopped)

More information at the projects page:

- [GitHub original](https://github.com/oriolrius/docker_container_exporter)
