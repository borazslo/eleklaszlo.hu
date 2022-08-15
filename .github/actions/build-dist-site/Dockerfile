
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
		curl \
#        wget \
    && gem install bundler \
    && bundle config --global silence_root_warning 1


COPY entrypoint.sh /

ENTRYPOINT ["sh", "/entrypoint.sh"]
