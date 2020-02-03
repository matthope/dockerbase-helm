FROM alpine:3.11.3 AS base
FROM base as build

RUN apk add --quiet --update \
	bash=~5.0 \
	ca-certificates=~20191127 \
	curl=~7 \
	gzip=~1.10 \
	git=~2.24 \
	jq=~1.6 \
	tar=~1.32

WORKDIR /

SHELL ["/bin/sh", "-o", "pipefail", "-c"]

ARG VERSIONS="2.16.1 2.14.1 2.12.3"
RUN mkdir /out ; for v in $VERSIONS ; do curl -s -L http://storage.googleapis.com/kubernetes-helm/helm-v${v}-linux-amd64.tar.gz | tar zx -C /tmp ; mv /tmp/linux-amd64/helm /out/helm-v${v} ; ls -lad /out/helm-v${v} ; done

RUN ln -s helm-v$( echo $VERSIONS | cut -d" " -f1 ) /out/helm ; ln -s /out/helm /usr/local/bin/helm

RUN mkdir -p "$(helm home)/plugins" ;\
	helm plugin install https://github.com/bacongobbler/helm-whatup ;\
	helm plugin install https://github.com/databus23/helm-diff --version master ;\
	helm plugin install https://github.com/futuresimple/helm-secrets ;\
	helm plugin install https://github.com/hypnoglow/helm-s3 ;\
	helm plugin install https://github.com/lrills/helm-unittest ;\
	helm plugin install https://github.com/maorfr/helm-backup ;\
	helm plugin install https://github.com/mbenabda/helm-local-chart-version ;\
	helm plugin install https://github.com/mstrzele/helm-edit

FROM base

RUN apk add --update --no-cache \
	bash=~5.0 \
	ca-certificates=~20191127 \
	curl=~7 \
	git=~2.24 \
	jq=~1.6

COPY --from=build /out/* /bin/
COPY --from=build /root/.helm /root/.helm/

RUN for i in /bin/helm* ; do ls -lad "$i" && "$i" version --client --short ; echo ; done

ENTRYPOINT ["/bin/helm"]
