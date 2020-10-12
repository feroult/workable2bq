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

RUN apt-get -y update 1>>/tmp/apt.log 2>&1 && apt-get -y install \
    antiword

RUN pip3 install google-cloud-storage google-cloud-bigquery docx2txt textract requests

# MuPDF
RUN wget https://mupdf.com/downloads/archive/mupdf-1.17.0-source.tar.gz && \
    tar -zxvf mupdf-1.17.0-source.tar.gz && \
    mv mupdf-1.17.0-source mupdf

RUN apt-get -y update 1>>/tmp/apt.log 2>&1 && apt-get -y install \
    mesa-common-dev libgl1-mesa-dev libx11-dev libxcursor-dev libxinerama-dev libxrandr-dev

RUN cd mupdf && \
      export CFLAGS="$CFLAGS -fPIC"; export CXXFLAGS="$CXXFLAGS -fPIC" && \
      make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local && \
      make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local install

RUN pip3 install PyMuPDF==1.17.0
##


RUN mkdir /export_views
RUN mkdir /export_candidates
RUN mkdir /export_resumes
RUN mkdir /export_resumes_binary
RUN mkdir /app
WORKDIR /app

COPY . .

RUN pip3 install Flask gunicorn requests
CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 app:app

