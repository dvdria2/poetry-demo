ARG PYTHON_VERSION=3.8

FROM python:${PYTHON_VERSION}-slim AS base

ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_USER_NAME
ARG DOCKER_USER_ID
ENV DOCKER_USER_NAME=$DOCKER_USER_NAME LANG=C.UTF-8 LC_ALL=C.UTF-8 PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 WORKDIR=/app
WORKDIR $WORKDIR
RUN useradd --skel /dev/null --shell /bin/bash --uid $DOCKER_USER_ID --create-home $DOCKER_USER_NAME
RUN chown $DOCKER_USER_NAME:$DOCKER_USER_NAME $WORKDIR
ENV PATH="/home/${DOCKER_USER_NAME}/.local/bin:${PATH}"
ARG PACKAGES_PATH=/home/${DOCKER_USER_NAME}/.local/lib/python${PYTHON_VERSION}/site-packages
RUN apt-get update && apt-get install -y --no-install-recommends \
        gettext \
        libpq5 \
        mime-support \
        libmariadb-dev-compat \
        gcc \
        unixodbc-dev \
        curl \
        build-essential \
        git \
        libpq-dev \
        make \
        ssh-client \
        libmariadb-dev \
        libssl-dev \ 
        libffi-dev \
        inotify-tools  \
        procps \
        vim-nox \
        bash-completion  \
    && rm -rf /var/lib/apt/lists/*
USER $DOCKER_USER_NAME

FROM base AS dev

SHELL ["/bin/bash", "-c"]
RUN touch ~/.bash_profile
RUN echo source /etc/bash_completion >> /home/$DOCKER_USER_NAME/.bashrc && source /home/$DOCKER_USER_NAME/.bashrc
RUN git clone --depth 1 --config core.autocrlf=false https://github.com/twolfson/sexy-bash-prompt 
RUN cd sexy-bash-prompt && make install
WORKDIR $WORKDIR
RUN pip install -U "pip~=22.2.0" setuptools
RUN pip install poetry
