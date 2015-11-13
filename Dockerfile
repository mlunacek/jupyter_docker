# Installs Jupyter Notebook and IPython kernel from the current branch
# Another Docker container should inherit with `FROM jupyter/notebook`
# to run actual services.

FROM ubuntu:14.04

MAINTAINER Project Jupyter <jupyter@googlegroups.com>

# Not essential, but wise to set the lang
# Note: Users with other languages should set this in their derivative image
ENV LANGUAGE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV PYTHONIOENCODING UTF-8

# Remove preinstalled copy of python that blocks our ability to install development python.
RUN DEBIAN_FRONTEND=noninteractive apt-get remove -yq \
        python3-minimal \
        python3.4 \
        python3.4-minimal \
        libpython3-stdlib \
        libpython3.4-stdlib \
        libpython3.4-minimal

# Python binary and source dependencies
RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        wget \
        git \
        language-pack-en \
        libcurl4-openssl-dev \
        libffi-dev \
        libsqlite3-dev \
        libzmq3-dev \
        pandoc \
        python \
        python3 \
        python-dev \
        python3-dev \
        sqlite3 \
        texlive-fonts-recommended \
        texlive-latex-base \
        texlive-latex-extra \
        zlib1g-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Tini
RUN curl -L https://github.com/krallin/tini/releases/download/v0.6.0/tini > tini && \
    echo "d5ed732199c36a1189320e6c4859f0169e950692f451c03e7854243b95f4234b *tini" | sha256sum -c - && \
    mv tini /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# Install the recent pip release
RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python2 get-pip.py && \
    python3 get-pip.py && \
    rm get-pip.py && \
    pip2 --no-cache-dir install requests[security] && \
    pip3 --no-cache-dir install requests[security]

# Install some dependencies.
RUN pip2 --no-cache-dir install ipykernel && \
    pip3 --no-cache-dir install ipykernel && \
    \
    python2 -m ipykernel.kernelspec && \
    python3 -m ipykernel.kernelspec

# Move notebook contents into place.
RUN git clone https://github.com/jupyter/notebook.git /usr/src/jupyter-notebook

# Install dependencies and run tests.
RUN BUILD_DEPS="nodejs-legacy npm" && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -yq $BUILD_DEPS && \
    \
    pip3 install --no-cache-dir --pre -e /usr/src/jupyter-notebook && \
    \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get purge -y --auto-remove \
        -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $BUILD_DEPS

# Run tests.
RUN pip2 install --no-cache-dir mock nose requests testpath && \
    pip3 install --no-cache-dir nose requests testpath && \
    \
    iptest2 && iptest3 && \
    \
    pip2 uninstall -y funcsigs mock nose pbr requests six testpath && \
    pip3 uninstall -y nose requests testpath

ENV NB_USER mlunacek
ENV NB_UID 1000

RUN useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir /home/$NB_USER/notebooks && \
    mkdir /home/$NB_USER/.jupyter && \
    mkdir /home/$NB_USER/.jupyter/custom && \
    mkdir /home/$NB_USER/.local && \
    chown -R $NB_USER:users /home/$NB_USER

VOLUME /home/$NB_USER/notebooks
WORKDIR /home/$NB_USER/notebooks

RUN pip install pandas





USER root 
EXPOSE 8888

ENTRYPOINT ["tini", "--"]
CMD ["start_notebook.sh"]

# Add local files as late as possible to avoid cache busting
COPY start_notebook.sh /usr/local/bin/
COPY .jupyter/jupyter_notebook_config.py /home/$NB_USER/.jupyter/jupyter_notebook_config.py
COPY .jupyter/custom/* /home/$NB_USER/.jupyter/custom/

RUN chown -R $NB_USER:users /home/$NB_USER/.jupyter





