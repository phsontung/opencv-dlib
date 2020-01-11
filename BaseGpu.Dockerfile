# https://www.learnopencv.com/install-opencv3-on-ubuntu
# https://docs.opencv.org/3.4/d6/d15/tutorial_building_tegra_cuda.html

ARG CUDA_VERSION=10.1
ARG CUDNN_VERSION=7

FROM nvidia/cuda:${CUDA_VERSION}-cudnn${CUDNN_VERSION}-devel-ubuntu18.04

ARG PYTHON_VERSION=3.6
ARG OPENCV_VERSION=3.4.5

# Needed for string substitution
SHELL ["/bin/bash", "-c"]

COPY . /

# ENV LD_LIBRARY_PATH /usr/local/${CUDA}/compat:$LD_LIBRARY_PATH

# Add CUDA libs paths
RUN CUDA_PATH=(/usr/local/cuda-*) && \
    CUDA=`basename $CUDA_PATH` && \
    echo "$CUDA_PATH/compat" >> /etc/ld.so.conf.d/${CUDA/./-}.conf && \
    ldconfig && \

# Install all dependencies for OpenCV
    apt-get -y update -qq --fix-missing && \
    apt-get -y install --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        $( [ ${PYTHON_VERSION%%.*} -ge 3 ] && echo "python${PYTHON_VERSION%%.*}-distutils" ) \
        git \
        wget \
        unzip \
        cmake \
        libtbb2 \
        gfortran \
        apt-utils \
        pkg-config \
        checkinstall \
        qt5-default \
        build-essential \
        libatlas-base-dev \
        libgtk2.0-dev \
        libavcodec57 \
        libavcodec-dev \
        libavformat57 \
        libavformat-dev \
        libavutil-dev \
        libswscale4 \
        libswscale-dev \
        libjpeg8-dev \
        libpng-dev \
        libtiff5-dev \
        libdc1394-22 \
        libdc1394-22-dev \
        libxine2-dev \
        libv4l-dev \
        libgstreamer1.0 \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-0 \
        libgstreamer-plugins-base1.0-dev \
        libglew-dev \
        libpostproc-dev \
        libeigen3-dev \
        libtbb-dev \
        zlib1g-dev \
        libsm6 \
        libxext6 \
        libxrender1 \
    && \

# install python dependencies
    sysctl -w net.ipv4.ip_forward=1 && \
    wget https://bootstrap.pypa.io/get-pip.py --progress=bar:force:noscroll && \
    python${PYTHON_VERSION} get-pip.py && \
    rm get-pip.py && \
    pip${PYTHON_VERSION} install numpy && \

# Install OpenCV
    wget https://github.com/opencv/opencv/archive/$OPENCV_VERSION.zip -O opencv.zip --progress=bar:force:noscroll && \
    unzip -q opencv.zip && \
    mv /opencv-$OPENCV_VERSION /opencv && \
    rm opencv.zip && \
    wget https://github.com/opencv/opencv_contrib/archive/$OPENCV_VERSION.zip -O opencv_contrib.zip --progress=bar:force:noscroll && \
    unzip -q opencv_contrib.zip && \
    mv /opencv_contrib-$OPENCV_VERSION /opencv_contrib && \
    rm opencv_contrib.zip && \

# Prepare build
    mkdir /opencv/build && \
    cd /opencv/build && \
    cmake \
      -D CMAKE_BUILD_TYPE=RELEASE \
      -D BUILD_PYTHON_SUPPORT=ON \
      -D BUILD_DOCS=ON \
      -D BUILD_PERF_TESTS=OFF \
      -D BUILD_TESTS=OFF \
      -D CMAKE_INSTALL_PREFIX=/usr/local \
      -D OPENCV_EXTRA_MODULES_PATH=/opencv_contrib/modules \
      -D BUILD_opencv_python3=$( [ ${PYTHON_VERSION%%.*} -ge 3 ] && echo "ON" || echo "OFF" ) \
      -D BUILD_opencv_python2=$( [ ${PYTHON_VERSION%%.*} -lt 3 ] && echo "ON" || echo "OFF" ) \
      -D PYTHON${PYTHON_VERSION%%.*}_EXECUTABLE=$(which python${PYTHON_VERSION}) \
      -D PYTHON_DEFAULT_EXECUTABLE=$(which python${PYTHON_VERSION}) \
      -D BUILD_EXAMPLES=OFF \
      -D WITH_IPP=OFF \
      -D WITH_FFMPEG=ON \
      -D WITH_GSTREAMER=ON \
      -D WITH_V4L=ON \
      -D WITH_LIBV4L=ON \
      -D WITH_TBB=ON \
      -D WITH_QT=ON \
      -D WITH_OPENGL=ON \
      -D WITH_CUDA=ON \
      -D CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda \
      -D CMAKE_LIBRARY_PATH=/usr/local/cuda/lib64/stubs \
      -D CUDA_ARCH_PTX="" \
      -D WITH_CUBLAS=ON \
      -D WITH_NVCUVID=ON \
      -D ENABLE_FAST_MATH=1 \
      -D CUDA_FAST_MATH=1 \
      -D ENABLE_PRECOMPILED_HEADERS=OFF \
      .. \
    && \

# Build, Test and Install
    cd /opencv/build && \
    make -j4 && \
    make install && \
    ldconfig && \

# Set the default python and install PIP packages
    update-alternatives --install /usr/bin/python${PYTHON_VERSION%%.*} python${PYTHON_VERSION%%.*} /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python${PYTHON_VERSION} 1 &&\

# install darknet, yolov3 py
    cd / \
    && git clone https://github.com/pjreddie/darknet.git \
    && cd /darknet \
    && sed -i '/GPU=0/c\GPU=1' Makefile \
    && sed -i '/OPENCV=0/c\OPENCV=1' Makefile \
    && sed -i '/CUDNN=0/c\CUDNN=1' Makefile \
    && make \
    && cp libdarknet.a libdarknet.so /usr/local/lib/ &&\

# Install yolov3 pydarknet
    cd / \
    && git clone https://github.com/phsontung/YOLO3-4-Py.git \
    && cd /YOLO3-4-Py \
    && apt-get install -y python3-dev \
    && pip3 install cython \
    && export DARKNET_HOME=/darknet \
    && export CUDA_HOME=/usr/local/cuda-10.1/ \
    && export GPU=1 \
    && export OPENCV=1 \
    && python3 setup.py build_ext --inplace \
    && cp pydarknet.cpython-36m-x86_64-linux-gnu.so /usr/local/lib/python3.6/dist-packages/ \
    && cp libdarknet.so /usr/local/lib/python3.6/dist-packages/ \
    && cp libdarknet.so /usr/lib \
# Install dlib
    && cd / \
    && pip install -r requirements.txt \
    # cleaning
    && apt-get -y remove \
        unzip \
        cmake \
        gfortran \
        apt-utils \
        pkg-config \
        checkinstall \
        build-essential \
        # libatlas-base-dev \
        libgtk2.0-dev \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libswscale-dev \
        libjpeg8-dev \
        libpng12-dev \
        libtiff5-dev \
        libdc1394-22-dev \
        libxine2-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libglew-dev \
        libpostproc-dev \
        libeigen3-dev \
        libtbb-dev \
        zlib1g-dev \
    && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /opencv /opencv_contrib /var/lib/apt/lists/* \
    && rm -rf /darknet /YOLO3-4-Py /opencv /opencv_contrib /var/lib/apt/lists/* \
    && rm -rf /app \


# Call default command.
    python --version && \
    python -c "import cv2 ; from pydarknet import Detector ; import dlib ; print(cv2.__version__)"
