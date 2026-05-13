FROM prom/pushgateway:latest
EXPOSE 9091
ENTRYPOINT ["/bin/pushgateway", "--web.cors.origin=.*"]
