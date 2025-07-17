FROM condaforge/mambaforge:24.9.0-0

LABEL name="QGIS-SAGA-NextGen"
LABEL description="QGIS with SAGA and NextGen plugin"

ARG DEBIAN_FRONTEND=noninteractive

# Headless environment
ENV PYTHONUNBUFFERED=1
ENV QT_QPA_PLATFORM=offscreen
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
ENV DISPLAY=:99

# Add wxWidgets 3.2 repository for Ubuntu focal
RUN apt-get update && apt-get install -y software-properties-common && \
    apt-key adv --fetch-keys https://repos.codelite.org/CodeLite.asc && \
    apt-add-repository 'deb https://repos.codelite.org/wx3.2/ubuntu/ focal universe' && \
    apt-get update

# System dependencies (fixed libnotify issue)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential cmake git wget curl unzip \
    libgl1-mesa-glx libegl1-mesa libxrandr2 libxss1 libxcursor1 \
    libxcomposite1 libasound2 libxi6 libxtst6 libxinerama1 \
    libfontconfig1 libxrender1 libglib2.0-0 \
    ca-certificates gnupg xvfb \
    flex make bison gcc g++ ccache \
    libproj-dev proj-data proj-bin \
    libgeos-dev libgdal-dev gdal-bin \
    python3-dev python3-numpy \
    libnotify4 libnotify-dev \
    libwxbase3.2-0-unofficial libwxbase3.2unofficial-dev libwxgtk3.2-0-unofficial libwxgtk3.2unofficial-dev wx3.2-headers wx-common \
    libgtk-3-dev libgdk-pixbuf2.0-dev libpango1.0-dev libatk1.0-dev \
    libpq-dev libopencv-dev libhpdf-dev unixodbc-dev \
    libfftw3-dev libgsl-dev \
    libsqlite3-dev libtiff5-dev libpng-dev \
    libcairo2-dev libfreetype6-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create conda environment
RUN mamba create -n pygile python=3.10 -y && \
    mamba run -n pygile conda config --env --add channels conda-forge && \
    mamba run -n pygile conda config --env --set channel_priority strict

# Install QGIS and Jupyter
RUN mamba install -n pygile -c conda-forge -y qgis jupyter jupyterlab && mamba clean -all -y

# Compile SAGA GIS (disable GUI to avoid libnotify linking issues)
RUN cd /tmp && \
    wget -q https://sourceforge.net/projects/saga-gis/files/SAGA%20-%209/SAGA%20-%209.3.2/saga-9.3.2.tar.gz && \
    tar -xzf saga-9.3.2.tar.gz && \
    cd saga-9.3.2/saga-gis && \
    mkdir build && cd build && \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/opt/saga \
        -DWITH_TRIANGLE=OFF \
        -DWITH_SYSTEM_SVM=ON \
        -DWITH_DEV_TOOLS=OFF \
        -DWITH_GUI=OFF \
        -DWITH_TOOLS_VIGRA=OFF \
        -DWITH_TOOLS_PDAL=OFF && \
    make -j$(nproc) && make install && ldconfig && \
    cd / && rm -rf /tmp/saga-9.3.2*

# Environment for SAGA
ENV PATH="/opt/saga/bin:$PATH"
ENV LD_LIBRARY_PATH="/opt/saga/lib"

# Install NextGen plugin
RUN mkdir -p /opt/conda/envs/pygile/share/qgis/python/plugins && \
    cd /tmp && \
    wget -q https://github.com/north-road/qgis-processing-saga-nextgen/archive/refs/heads/master.zip && \
    unzip master.zip && \
    mv qgis-processing-saga-nextgen-master /opt/conda/envs/pygile/share/qgis/python/plugins/processing_saga_nextgen && \
    rm master.zip

# Configure SAGA path for plugin
RUN mkdir -p /root/.local/share/QGIS/QGIS3/profiles/default && \
    echo -e "[ProcessingConfig]\nSAGANG_FOLDER=/opt/saga\nSAGANG_ACTIVATE=true\n[plugins]\nprocessing_saga_nextgen=true" > /root/.local/share/QGIS/QGIS3/profiles/default/QGIS3.ini

# Create entrypoint script
RUN printf '#!/bin/bash\n\
source /opt/conda/etc/profile.d/conda.sh\n\
conda activate pygile\n\
cd /workspace\n\
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root \\\n\
  --ServerApp.token="" --ServerApp.password="" \\\n\
  --ServerApp.allow_origin="*" --ServerApp.disable_check_xsrf=True\n\
' > /entrypoint.sh && chmod +x /entrypoint.sh

WORKDIR /workspace
EXPOSE 8888
CMD ["/entrypoint.sh"]