FROM nvidia/cuda:10.0-cudnn7-devel

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get install -y python3-pip python3-dev

RUN apt-get install wget nano apt-utils lsb-core git g++ make libprotobuf-dev protobuf-compiler libopencv-dev \
libgoogle-glog-dev libboost-all-dev libcaffe-cuda-dev libhdf5-dev libatlas-base-dev -y 
RUN apt-get update && apt-get -y install sudo

COPY Requirements.txt ./
RUN pip3 install -r Requirements.txt
RUN sudo rm Requirements.txt

COPY bugPytube.sh ./
COPY __main__.py ./
COPY playlist.py ./

RUN sudo sh bugPytube.sh
RUN sudo rm bugPytube.sh

RUN useradd -m lse && echo "lse ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/lse && \
    chmod 0770 /etc/sudoers.d/lse
RUN sudo wget https://github.com/Kitware/CMake/releases/download/v3.16.0/cmake-3.16.0-Linux-x86_64.tar.gz && \
sudo tar xzf cmake-3.16.0-Linux-x86_64.tar.gz -C /opt && \
sudo rm cmake-3.16.0-Linux-x86_64.tar.gz 

ENV PATH="/opt/cmake-3.16.0-Linux-x86_64/bin:${PATH}"

RUN sudo git clone https://github.com/CMU-Perceptual-Computing-Lab/openpose.git

WORKDIR /openpose/build

RUN sudo apt-get update
RUN  cmake -D CMAKE_INSTALL_PREFIX=/openpose/build \
    -D BUILD_CAFFE=ON \
    -D BUILD_EXAMPLES=ON \
    -D GPU_MODE=CUDA \
    -D CMAKE_BUILD_TYPE=Release \
    -D DOWNLOAD_BODY_COCO_MODEL=ON \
    -D DOWNLOAD_BODY_MPI_MODEL=ON \
    -D DOWNLOAD_HAND_MODEL=ON \
    -D DOWNLOAD_FACE_MODEL=ON .. 
USER lse
RUN sudo make -j`nproc` && \
   sudo make install

RUN sudo locale-gen es_ES.UTF-8
ENV LANG es_ES.UTF-8
ENV LANGUAGE es_ES:es
ENV LC_ALL es_ES.UTF-8

RUN sudo apt-get update && \
    sudo apt-get -y install ffmpeg
WORKDIR ../../
COPY lsedataset/ lsedataset/
WORKDIR lsedataset/
USER root
ENTRYPOINT ["python3"]
CMD ["lsedataset.py"]
