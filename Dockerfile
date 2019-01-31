FROM alpine:3.8 as build

RUN apk add --quiet --update \
	bash=~4.4 \
	ca-certificates=~20171114 \
	curl=~7.61 \
	gzip=~1.9 \
	git=~2.18 \
	jq=~1.6 \
	tar=~1.31 

WORKDIR /

ARG VERSIONS="2.12.3 2.12.1 2.9.1"
RUN mkdir /out ; for v in $VERSIONS ; do curl -s -L http://storage.googleapis.com/kubernetes-helm/helm-v${v}-linux-amd64.tar.gz | tar zx -C /tmp ; mv /tmp/linux-amd64/helm /out/helm-v${v} ; ls -lad /out/helm-v${v} ; done

RUN ln -s helm-v$( echo $VERSIONS | cut -d" " -f1 ) /out/helm ; ln -s /out/helm /usr/local/bin/helm

RUN mkdir -p "$(helm home)/plugins"
RUN helm plugin install https://github.com/databus23/helm-diff 
RUN helm plugin install https://github.com/hypnoglow/helm-s3 
RUN helm plugin install https://github.com/futuresimple/helm-secrets 

FROM alpine:3.8

RUN apk add --update --no-cache \
	ca-certificates=~20171114 \
	git=~2.18 

COPY --from=build /out/* /bin/
COPY --from=build /root/.helm /root/.helm/

RUN for i in /bin/helm* ; do ls -lad $i && $i version --client --short ; echo ; done

ENTRYPOINT ["/bin/helm"]
