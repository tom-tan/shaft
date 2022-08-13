FROM ghcr.io/tom-tan/ldc:1.28.1

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && apt-get install -y --no-install-recommends python-is-python3 python3-pip docker-ce-cli \
                                                                 libclang-dev libpcre2-dev clang make && \
    ln -s /usr/lib/x86_64-linux-gnu/libclang-10.so /usr/lib/x86_64-linux-gnu/libclang.so && \
    pip install cwltest && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/library-scripts

COPY setup-njs.sh /tmp

RUN /tmp/setup-njs.sh 0.7.6 /opt/njs && rm /tmp/setup-njs.sh

ENV NJS_BASE /opt/njs
