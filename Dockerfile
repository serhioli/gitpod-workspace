FROM buildpack-deps:jammy

COPY --from=gitpod/workspace-base:latest /usr/bin/install-packages /usr/bin/upgrade-packages /usr/bin/

RUN yes | unminimize \
    && install-packages \
        ca-certificates \
        lsb-release \
        curl \
        wget \
        gnupg \
        build-essential \
        locales \
        man-db \
        software-properties-common \
        sudo \
        lsof \
        ssl-cert \
    # Git repo
    && add-apt-repository -y ppa:git-core/ppa \
    # Docker repo
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null \
    # PHP repo
    && add-apt-repository -y ppa:ondrej/php \
    # Symfony CLI repo
    && curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && upgrade-packages \
    && install-packages \
        htop \
        zip \
        unzip \
        bash-completion \
        jq \
        less \
        nano \
        ripgrep \
        stow \
        time \
        multitail \
        mysql-client postgresql-client \
        git git-lfs \
        docker-ce docker-ce-cli containerd.io \
        symfony-cli \
    && install-packages \
        php \
        php-all-dev \
        php-bcmath \
        php-common \
        php-curl \
        php-date \
        php-gd \
        php-intl \
        php-json \
        php-mbstring \
        php-mysql \
        php-net-ftp \
        php-pgsql \
        php-pear \
        php-sqlite3 \
        php-tokenizer \
        php-xml \
        php-zip \
    # Register ru lang locale
    && locale-gen ru_RU.UTF-8 en_US.UTF-8 \
    && git lfs install --system

ENV LANG=ru_RU.UTF-8 \
    LANGUAGE=ru_RU:ru \
    LC_ALL=ru_RU.UTF-8

### User ###
# '-l': see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd -l -u 33333 -G sudo,docker -md /home/gitpod -s /bin/bash -p gitpod gitpod \
    # passwordless sudo for users in the 'sudo' group
    && sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers \
    # To emulate the workspace-session behavior within dazzle build env
    && mkdir /workspace && chown -hR gitpod:gitpod /workspace

ENV HOME=/home/gitpod
WORKDIR $HOME

USER gitpod
# use sudo so that user does not get sudo usage info on (the first) login
RUN sudo echo "Running 'sudo' for Gitpod: success" && \
    # create .bashrc.d folder and source it in the bashrc
    mkdir -p /home/gitpod/.bashrc.d && \
    (echo; echo "for i in \$(ls -A \$HOME/.bashrc.d/); do source \$HOME/.bashrc.d/\$i; done"; echo) >> /home/gitpod/.bashrc && \
    # create a completions dir for gitpod user
    mkdir -p /home/gitpod/.local/share/bash-completion/completions

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY --from=composer:2 --chown=gitpod:gitpod /tmp/keys.dev.pub /tmp/keys.tags.pub $HOME/.composer/
# < Composer
