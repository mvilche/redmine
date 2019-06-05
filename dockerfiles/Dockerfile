FROM alpine:3.9
RUN apk add --update --no-cache git ruby-webrick unzip shadow curl su-exec ruby-etc ruby-json ruby-bigdecimal tzdata gc gcc make mysql-dev ruby ruby-dev musl-dev
RUN addgroup -S redmine && adduser -h /opt/redmine -S -G redmine redmine && \
gem install rdoc &> /dev/null; gem install netaddr && gem install rdoc && gem install bundler
COPY run.sh /usr/bin/run.sh
WORKDIR /opt/redmine
VOLUME ["/opt/redmine"]
EXPOSE 3000
ENTRYPOINT ["/usr/bin/run.sh"]
CMD ["webrick", "-e", "production"]
