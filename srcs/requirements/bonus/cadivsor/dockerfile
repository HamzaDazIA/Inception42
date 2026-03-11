FROM debian:bookworm

RUN apt-get update -y && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN wget https://github.com/google/cadvisor/releases/download/v0.47.0/cadvisor-v0.47.0-linux-amd64 -O /usr/bin/cadvisor
RUN chmod +x /usr/bin/cadvisor
EXPOSE 9080
ENTRYPOINT ["cadvisor", "-port=9080"]
