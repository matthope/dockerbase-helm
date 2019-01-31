# dockerbase-helm

Docker base image for [helm](https://helm.sh).

Either use it standalone:

```sh
docker run dockerbase-helm help
```

or as a base image.

It has multiple versions of helm CLI installed, for example:

```sh
docker run --entrypoint /bin/helm-2.9.1 dockerbase-helm version
```
