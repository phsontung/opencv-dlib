FROM borda/docker_python-opencv-ffmpeg

WORKDIR /app
COPY . /app

RUN apt-get update && apt-get install -y build-essential cmake pkg-config \
    && python --version \
    && pip install --upgrade pip\
    && pip install -U -r requirements.txt \
    && apt-get remove -y build-essential cmake pkg-config \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /opencv /opencv_contrib /var/lib/apt/lists/* \
    && rm requirements.txt
