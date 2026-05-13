FROM prom/pushgateway:latest AS pushgateway

FROM nginx:alpine
RUN apk add --no-cache supervisor
COPY --from=pushgateway /bin/pushgateway /bin/pushgateway

RUN echo '[supervisord]' > /etc/supervisord.conf && \
    echo 'nodaemon=true' >> /etc/supervisord.conf && \
    echo '[program:pushgateway]' >> /etc/supervisord.conf && \
    echo 'command=/bin/pushgateway --web.listen-address=:9091' >> /etc/supervisord.conf && \
    echo '[program:nginx]' >> /etc/supervisord.conf && \
    echo 'command=nginx -g "daemon off;"' >> /etc/supervisord.conf

RUN printf 'events{}\nhttp{\n  server{\n    listen 10000;\n    location /{\n      proxy_pass http://localhost:9091;\n      add_header Access-Control-Allow-Origin *;\n      add_header Access-Control-Allow-Methods "GET,POST,DELETE,OPTIONS";\n      add_header Access-Control-Allow-Headers "*";\n      if ($request_method = OPTIONS){return 204;}\n    }\n  }\n}' > /etc/nginx/nginx.conf

EXPOSE 10000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
