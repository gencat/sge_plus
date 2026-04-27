ARG OS_VERSION=slim-bookworm
ARG RUBY_IMAGE_VERSION=3.3.4

FROM ruby:${RUBY_IMAGE_VERSION}-${OS_VERSION}

ARG RUBYGEMS_VERSION=3.3.22
ARG BUNDLER_VERSION=2.6.5
ARG NODE_VERSION=18.17.1

ENV DEBIAN_FRONTEND=noninteractive

ENV HOME=/var/www
ENV APP_HOME=$HOME/sge_plus

# Force Madrid's timezone
ENV TZ=Europe/Madrid
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies
RUN apt -qq update && apt upgrade -y
RUN apt -qq install -y \
    build-essential \
    graphviz \
    imagemagick \
    libicu-dev \
    libpq-dev \
    gettext-base \
    tzdata \
    vim \
    locales \
    p7zip \
    ca-certificates \
    curl \
    cron \
    python3 \
    git \
    icu-devtools \
    zlib1g-dev \
    # required by wkhtmltopdf
    xfonts-base \
    xfonts-75dpi \
    fontconfig \
    libjpeg62-turbo \
    libxrender1 \
    xfonts-encodings \
    xfonts-utils \
    libx11-6 \
    libxext6 \
    && apt install -y --no-install-recommends libjemalloc2

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2
ENV MALLOC_CONF='dirty_decay_ms:1000,narenas:2,background_thread:true'

# Install wkhtmltopdf
RUN curl -L -o wkhtmltox.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb \
    && dpkg -i wkhtmltox.deb || true \
    && apt install -f -y \
    && rm wkhtmltox.deb

# Define volumes
VOLUME $APP_HOME/storage
VOLUME $APP_HOME/log

##############################
# Update Ruby ecosystem
##############################
RUN gem update --system $RUBYGEMS_VERSION && update_rubygems
RUN gem install bundler:$BUNDLER_VERSION \
 && gem install stringio:3.1.7

##############################
# Install NodeJs & Yarn
##############################
ENV NODE_VERSION=${NODE_VERSION}
RUN apt update
RUN apt -y install curl gnupg
RUN curl -fsSL https://deb.nodesource.com/node_18.x/pool/main/n/nodejs/nodejs_18.17.1-1nodesource1_amd64.deb -o nodejs_18.17.1.deb \
 && dpkg -i nodejs_${NODE_VERSION}.deb \
 && rm nodejs_${NODE_VERSION}.deb
RUN npm -v
RUN npm install -g yarn

##############################
# Prepare working directory & other configurations
##############################

# Create app dir
RUN mkdir -p $APP_HOME
RUN mkdir -p $APP_HOME/tmp

WORKDIR $APP_HOME
RUN chown -R www-data:www-data $HOME
RUN chown -R www-data:www-data $APP_HOME
RUN chown -R www-data:www-data /var/www/.npm

##############################
# Copy app code into docker image
##############################
ADD . $APP_HOME
RUN rm -Rf tmp/*
RUN chown -R www-data:www-data $APP_HOME

USER www-data
ENV RAILS_ENV=production
WORKDIR $APP_HOME

##############################
# Install Node dependencies
##############################
RUN rm -Rf node_modules/ && npm cache clean --force

RUN npm install

# ##############################
# # Install Bundler dependencies
# ##############################

# ADD Gemfile Gemfile
# ADD Gemfile.lock Gemfile.lock

RUN cp config/application.example.yml config/application.yml
RUN cp config/puma.example.rb config/puma.rb
RUN bundle config --without development test \
 && bundle config set deployment 'true' \
 && bundle install --jobs=10

# ##############################
# # Build app
# ##############################
ENV DISABLE_SPRING=1
RUN RAILS_ENV=production SECRET_KEY_BASE=WHATEVER DATABASE_URL=postgresql://localhost/dummy DOCKER=1 bundle exec rake shakapacker:clobber shakapacker:compile

# make sure nothing gets leacked
RUN rm config/application.yml && touch config/application.yml

# Add a tmp folder for pids
RUN mkdir -p tmp/pids

##############################
# Clean up APT and bundler when done.
##############################
USER root
# clean caches
RUN apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# remove compilation tools
RUN apt -y remove build-essential libpq-dev libicu-dev curl python3 git icu-devtools zlib1g-dev

USER www-data

##############################
# RUN image as www-data
##############################
#################RUN chown -R www-data:www-data $APP_HOME
USER www-data
WORKDIR $APP_HOME

# Print the UID and GID (only one CMD is allowed in a Dockerfile, it executes when the container starts)
CMD ["sh", "-c", "echo 'Inside Container:' && echo 'User: `$(whoami)` UID: `$(id -u)` GID: `$(id -g)`'"]
