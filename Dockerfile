FROM prom/prometheus:latest
EXPOSE 9090
COPY prometheus.yml /etc/prometheus/prometheus.yml
EXPOSE 9090
CMD ["--config.file=/etc/prometheus/prometheus.yml", "--web.enable-lifecycle"]
FROM prom/pushgateway:latest
EXPOSE 9091
