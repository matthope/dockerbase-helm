FROM alpine:3.11.3 AS base
FROM base as build

RUN apk add --quiet --no-cache --update \
	bash=~5.0 \
	ca-certificates=~20191127 \
	curl=~7 \
	gzip=~1.10 \
	git=~2.24 \
	jq=~1.6 \
	tar=~1.32

WORKDIR /out

FROM build AS helm3

SHELL ["/bin/sh", "-o", "pipefail", "-c"]

ARG VERSIONS="3.4.2"
RUN install -d /out ; for v in $VERSIONS ; do curl -s -L https://get.helm.sh/helm-v${v}-linux-amd64.tar.gz | tar zx -C /tmp ; mv /tmp/linux-amd64/helm /out/helm-v${v} ; ls -lad /out/helm-v${v} ; done

RUN ln -s helm-v$( echo $VERSIONS | cut -d" " -f1 ) /out/helm3 ; ln -s /out/helm3 /usr/local/bin/helm3 ; ln -s helm3 /out/helm

RUN mkdir -p "/root/.helm/plugins" ;\
	helm3 plugin install https://github.com/aslafy-z/helm-git ;\
	helm3 plugin install https://github.com/databus23/helm-diff --version master ;\
	helm3 plugin install https://github.com/futuresimple/helm-secrets ;\
	helm3 plugin install https://github.com/helm/helm-2to3.git ;\
	helm3 plugin install https://github.com/lrills/helm-unittest ;\
	helm3 plugin install https://github.com/mbenabda/helm-local-chart-version ;\
	echo

FROM build AS helm2

SHELL ["/bin/sh", "-o", "pipefail", "-c"]

ARG VERSIONS="2.17.0 2.14.3"
RUN install -d /out ; for v in $VERSIONS ; do curl -s -L https://get.helm.sh/helm-v${v}-linux-amd64.tar.gz | tar zx -C /tmp ; mv /tmp/linux-amd64/helm /out/helm-v${v} ; ls -lad /out/helm-v${v} ; done

RUN ln -s helm-v$( echo $VERSIONS | cut -d" " -f1 ) /out/helm2 ; ln -s /out/helm2 /usr/local/bin/helm2

RUN mkdir -p "$(helm2 home)/plugins" ;\
	helm2 plugin install https://github.com/aslafy-z/helm-git ;\
	helm2 plugin install https://github.com/databus23/helm-diff --version 3.1.2 ;\
	helm2 plugin install https://github.com/futuresimple/helm-secrets ;\
	helm2 plugin install https://github.com/helm/helm-2to3.git ;\
	helm2 plugin install https://github.com/lrills/helm-unittest ;\
	helm2 plugin install https://github.com/mbenabda/helm-local-chart-version ;\
	echo

FROM build AS kustomize
SHELL ["/bin/sh", "-o", "pipefail", "-c"]

ARG KUSTOMIZE_VERSION=3.8.1
RUN curl -L https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize/v${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz | \
    tar xzC /out && \
    chmod +x /out/kustomize

RUN mkdir -p /root/.config/kustomize/plugin

FROM build AS kubectl
SHELL ["/bin/sh", "-o", "pipefail", "-c"]

ARG KUBERNETES_VERSION=1.18.6
RUN curl --fail --location -o /out/kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /out/kubectl && /out/kubectl version --client

FROM build AS helmfile

COPY --from=quay.io/roboll/helmfile:v0.135.0 /usr/local/bin/helmfile /out/helmfile

FROM base

RUN apk add --update --no-cache \
	bash=~5.0 \
	ca-certificates=~20191127 \
	curl=~7 \
	git=~2.24 \
	jq=~1.6

COPY --from=helm2 /out/* /bin/
COPY --from=helm2 /root/.helm /root/.helm/

COPY --from=helm3 /out/* /bin/
COPY --from=helm3 /root/.local/ /root/.local/


COPY --from=kustomize /out/* /bin/
COPY --from=kustomize /root/.config /root/.config/

COPY --from=kubectl /out/* /bin/

COPY --from=helmfile /out/* /bin/

ENTRYPOINT ["/bin/helm"]
