
FROM jekyll/builder


RUN apk update && \
    apk add  \
        bats \
#        ca-certificates \
#        curl \
#        libffi6 \
#        make \
#        shellcheck \
#        libffi6 \
#        git-all \
        openssh-client \
#        wget \
    && gem install bundler:2.0.2 \
    && bundle config --global silence_root_warning 1


COPY entrypoint.sh /

ENTRYPOINT ["sh", "/entrypoint.sh"]
