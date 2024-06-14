ARG DC=ldc
ARG DC_VERSION=1.28.1

FROM ghcr.io/tom-tan/${DC}:${DC_VERSION} as NJS

ARG NJS_VERSION=0.7.6

COPY setup-njs.sh /tmp

RUN apt-get update && apt-get install -y --no-install-recommends libpcre2-dev make
RUN echo "njs version: '${NJS_VERSION}'"
RUN /tmp/setup-njs.sh ${NJS_VERSION} /opt/njs


FROM ghcr.io/tom-tan/${DC}:${DC_VERSION}

ENV NJS_BASE /opt/njs
ENV CPATH $CPATH:$NJS_BASE/include
ENV LIBRARY_PATH $LIBRARY_PATH:$NJS_BASE/lib

COPY --from=NJS /opt/njs /opt/njs

RUN apt-get update && apt-get install -y --no-install-recommends libpcre2-dev
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts
