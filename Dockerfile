FROM prom/pushgateway:latest AS pushgateway

FROM nginx:alpine
RUN apk add --no-cache supervisor
COPY --from=pushgateway /bin/pushgateway /bin/pushgateway

RUN printf '[supervisord]\nnodaemon=true\n[program:pushgateway]\ncommand=/bin/pushgateway --web.listen-address=:9091\n[program:nginx]\ncommand=nginx -g "daemon off;"\n' > /etc/supervisord.conf

COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 10000
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
