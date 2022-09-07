ARG DC=ldc
ARG VERSION=1.28.1

FROM ghcr.io/tom-tan/${DC}:${VERSION} as NJS

COPY setup-njs.sh /tmp

RUN apt-get update && apt-get install -y --no-install-recommends libpcre2-dev make
RUN /tmp/setup-njs.sh 0.7.6 /opt/njs


FROM ghcr.io/tom-tan/${DC}:${VERSION}

ENV NJS_BASE /opt/njs
COPY --from=NJS /opt/njs /opt/njs

RUN apt-get update && apt-get install -y --no-install-recommends python-is-python3 python3-pip \
                                                                 libclang-dev libpcre2-dev clang
RUN ln -s /usr/lib/$(uname -m)-linux-gnu/libclang-14.so /usr/lib/$(uname -m)-linux-gnu/libclang.so
RUN pip install cwltest
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts
