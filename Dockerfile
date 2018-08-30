FROM tensorflow/tensorflow:1.10.0-devel-gpu-py3

RUN apt-get update --fix-missing

RUN apt-get install -y \
    git \
    libopenblas-dev

RUN pip3 install --upgrade --no-cache-dir \
    pystan==2.17.1.0 \
    fbprophet==0.3.post2 \
    surprise==0.1 \
    plotly==3.1.1 \
    category_encoders==1.2.8

RUN ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/cuda/lib64/libcuda.so

# faiss for GPU
WORKDIR /
RUN git clone https://github.com/facebookresearch/faiss.git
WORKDIR faiss
RUN ./configure --with-python=python3 --with-blas=/usr/lib/libopenblas.so.0 --with-cuda=/usr/local/cuda-9.0 \
    && make misc/test_blas \
    && ./misc/test_blas \
    && make -j 4 \
    && make install \
    && make -j 4 py \
    && make -C python install \
    && cd /faiss/gpu \
    && make -j 4 \
    && cd /faiss/python; make _swigfaiss_gpu.so \
    && rm -rf /faiss

# OpenCV 3 without CUDA
RUN apt-get install -y \
        build-essential \
        cmake \
        libgtk2.0-dev \
        pkg-config \
        libavcodec-dev \
        libavformat-dev \
        libswscale-dev \
        libtbb2 \
        libtbb-dev \
        libjpeg-dev \
        libpng-dev \
        libtiff-dev \
        libjasper-dev \
        libdc1394-22-dev

WORKDIR /
ENV OPENCV_VERSION "3.4.2"
RUN git clone https://github.com/opencv/opencv.git \
    && cd opencv \
    && git checkout tags/${OPENCV_VERSION} \
    && mkdir build \
    && cd build \
    && cmake \
        -DBUILD_opencv_java=OFF \
        -D WITH_EIGEN=ON \
        -D WITH_TBB=ON \
        -D WITH_OPENMP=ON \
        -D WITH_IPP=ON \
        -D WITH_CUDA=OFF \
        -D CMAKE_BUILD_TYPE=RELEASE \
        -D BUILD_EXAMPLES=OFF \
        -D ENABLE_FAST_MATH=1 \
        -D CPU_DISPATCH=SSE4_2,AVX2 \
        -D BUILD_DOCS=OFF \
        -D BUILD_PERF_TESTS=OFF \
        -D BUILD_TESTS=OFF \
        -D WITH_CSTRIPES=ON \
        -D WITH_OPENCL=ON \
        -D WITH_OPENGL=ON \
        -D CMAKE_INSTALL_PREFIX=/usr \
        -D PYTHON_EXECUTABLE=$(which python3) \
        -D PYTHON_INCLUDE_DIR=/usr/include/python3.5m \
        -D PYTHON_PACKAGES_PATH=/usr/lib/python3/dist-packages .. \
    && make -j 4 \
    && make install \
    && cd / \
    && rm -rf /opencv

# xgboost for GPU
RUN apt-get update
RUN apt-get install -y cmake
WORKDIR /
RUN git clone --recursive https://github.com/dmlc/xgboost
RUN cd xgboost; mkdir build; cd build; cmake .. -DUSE_CUDA=ON -DUSE_NCCL=ON; make -j 4 \
    && cd /xgboost/python-package; python3 setup.py install \
    && rm -rf /xgboost

# lightgbm for GPU
# Add OpenCL ICD files for LightGBM
RUN mkdir -p /etc/OpenCL/vendors && \
    echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd
    
RUN apt-get install --no-install-recommends -y \
    git \
    cmake \
    build-essential \
    libboost-dev \
    libboost-system-dev \
    libboost-filesystem-dev
RUN cd /usr/local/src && mkdir lightgbm && cd lightgbm && \
    git clone --recursive https://github.com/Microsoft/LightGBM && \
    cd LightGBM && mkdir build && cd build && \
    cmake -DUSE_GPU=1 -DOpenCL_LIBRARY=/usr/local/cuda/lib64/libOpenCL.so -DOpenCL_INCLUDE_DIR=/usr/local/cuda/include/ .. && \ 
    make -j 4 OPENCL_HEADERS=/usr/local/cuda-9.0/targets/x86_64-linux/include LIBOPENCL=/usr/local/cuda-9.0/targets/x86_64-linux/lib
RUN cd /usr/local/src/lightgbm/LightGBM/python-package && \
    python3 setup.py install --precompile && \
    rm -rf /lightgbm

RUN mkdir /app
RUN mkdir /data
