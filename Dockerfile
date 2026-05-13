FROM prom/pushgateway:latest
EXPOSE 9091
CMD ["--web.cors.origin=.*"]
