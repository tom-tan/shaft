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

RUN git clone https://github.com/nginx/njs.git -b 0.7.6 && \
    cd njs && ./configure --test262=NO --no-openssl && make libnjs && cd .. && \
    install -d /opt/njs/include /opt/njs/lib /opt/njs/doc && \
    install -d /opt/njs/include /opt/njs/lib /opt/njs/ && \
    install -m 644 njs/build/libnjs.a /opt/njs/lib && \
    install -m 644 njs/src/*.h /opt/njs/include && \
    install -m 644 njs/build/njs_auto_config.h /opt/njs/include && \
    install -m 644 njs/LICENSE /opt/njs/doc && \
    rm -rf njs

ENV NJS_BASE /opt/njs
