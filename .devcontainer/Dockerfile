ARG VARIANT
ARG DC_NAME
ARG DC_VERSION

FROM mcr.microsoft.com/vscode/devcontainers/base:${VARIANT} AS common-env
ONBUILD ARG DBASE=/dlang

FROM common-env AS dmd-env
ONBUILD ARG DBASE=${DBASE}
ONBUILD ARG DC_NAME=${DC_NAME}
ONBUILD ARG DC_VERSION=${DC_VERSION}
ONBUILD ARG D_PATH=${DBASE}/dc/linux/bin64
ONBUILD ARG D_LIBRARY_PATH=${DBASE}/dc/linux/lib64
ONBUILD ARG D_LD_LIBRARY_PATH=${DBASE}/dc/linux/lib64
ONBUILD ARG DMD_PATH=${D_PATH}
ONBUILD ENV DMD=dmd
ONBUILD ENV DC=dmd

FROM common-env AS ldc-env
ONBUILD ARG DBASE=${DBASE}
ONBUILD ARG DC_NAME=${DC_NAME}
ONBUILD ARG DC_VERSION=${DC_VERSION}
ONBUILD ARG D_PATH=${DBASE}/dc/bin
ONBUILD ARG D_LIBRARY_PATH=${DBASE}/dc/lib
ONBUILD ARG D_LD_LIBRARY_PATH=${DBASE}/dc/lib
ONBUILD ARG DMD_PATH=${D_PATH}
ONBUILD ENV DMD=ldmd2
ONBUILD ENV DC=ldc2
ONBUILD ARG EXTRA_PKG=libxml2

FROM common-env AS gdc-env
ONBUILD ARG DBASE=${DBASE}
ONBUILD ARG DC_NAME=${DC_NAME}
ONBUILD ARG DC_VERSION=${DC_VERSION}
ONBUILD ARG D_PATH=${DBASE}/dub:${DBASE}/dc/bin
ONBUILD ARG D_LIBRARY_PATH=${DBASE}/dc/lib64
ONBUILD ARG D_LD_LIBRARY_PATH=${DBASE}/dc/lib64
ONBUILD ARG DMD_PATH=${DBASE}/dc/bin
ONBUILD ENV DMD=gdmd
ONBUILD ENV DC=gdc
ONBUILD ARG EXTRA_PKG=perl-modules

FROM ${DC_NAME}-env

ENV DEBIAN_FRONTEND=noninteractive

RUN set -ex && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates gpg xz-utils \
        gcc libc6-dev lld \
        gdb ${EXTRA_PKG} && \
    update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.lld" 20 && \
    update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.gold" 10 && \
    update-alternatives --install "/usr/bin/ld" "ld" "/usr/bin/ld.bfd" 10 && \
	curl -fsS https://dlang.org/install.sh | bash -s ${DC_NAME}-${DC_VERSION} -p ${DBASE} && \
    ln -s ${DBASE}/${DC_NAME}-${DC_VERSION} ${DBASE}/dc && \
    chmod 755 -R ${DBASE} && chown -R vscode:vscode ${DBASE} && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

# Prevents conflicts with system libs
RUN if [ "${DC_NAME}" = "gdc" ]; then \
        rm ${D_LIBRARY_PATH}/libstdc++.so.6*; \
    fi

# Tweaks for code-d settings
RUN if [ "${DC_NAME}" != "dmd" ]; then ln -s ${DMD_PATH}/${DMD} ${DMD_PATH}/dmd; fi
RUN if [ "${DC_NAME}" = "gdc" ]; then \
        ln -s ${DBASE}/dc/lib/gcc/x86_64-unknown-linux-gnu/${DC_VERSION}/include/d /dlang/dc/import; \
    fi

ENV PATH=${D_PATH}:${PATH}
ENV LIBRARY_PATH=${D_LIBRARY_PATH}:${LIBRARY_PATH}
ENV LD_LIBRARY_PATH=${D_LD_LIBRARY_PATH}:${LD_LIBRARY_PATH}
