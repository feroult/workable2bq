FROM debian:latest

# Tools
RUN apt-get -y update 1>>/tmp/apt.log 2>&1 && apt-get -y install \
  nmap netcat wget curl vim net-tools git sudo zip bash-completion \
  build-essential manpages-dev python3-pip 1>>/tmp/apt.log 2>&1 && \
  rm -rf /var/lib/apt/lists/* && \
  rm /tmp/apt.log
RUN pip3 install --no-cache-dir -U crcmod

# GCloud
RUN curl https://sdk.cloud.google.com | \
    CLOUDSDK_CORE_DISABLE_PROMPTS=1 CLOUDSDK_INSTALL_DIR="/opt" bash && \
    /opt/google-cloud-sdk/bin/gcloud config set disable_usage_reporting true && \
    echo "source /opt/google-cloud-sdk/path.bash.inc" >> /etc/bash.bashrc && \
    echo "source /opt/google-cloud-sdk/completion.bash.inc" >> /etc/bash.bashrc && \
    /opt/google-cloud-sdk/bin/gcloud components install beta -q
ENV PATH "/opt/google-cloud-sdk/bin:$PATH"

RUN pip3 install google-cloud-storage
RUN pip3 install requests

RUN mkdir /app
WORKDIR /app

COPY . .

