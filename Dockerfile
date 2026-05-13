FROM prom/pushgateway:latest
EXPOSE 9091

FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 9091
