FROM ubuntu:jammy

ARG DEBIAN_FRONTEND="noninteractive"

ENV APP_DIR="/app" CONFIG_DIR="/config" PUID="99" PGID="100" UMASK="002" TZ="Europe/Paris" ARGS=""
ENV XDG_CONFIG_HOME="${CONFIG_DIR}/.config" XDG_CACHE_HOME="${CONFIG_DIR}/.cache" XDG_DATA_HOME="${CONFIG_DIR}/.local/share" LANG="fr_FR.UTF-8" LANGUAGE="fr_FR.UTF-8" LC_ALL="fr_FR.UTF-8"
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

COPY root/ /

VOLUME ["${CONFIG_DIR}"]
ENTRYPOINT ["/init"]

# make folders
RUN mkdir "${APP_DIR}"

# Configure timezone
RUN echo "Europe/Paris" > /etc/timezone

# create user
RUN useradd -u 99 -U -d "${CONFIG_DIR}" -s /bin/false ubuntu && usermod -G users ubuntu

RUN apt-get update
RUN apt-get -y install apt-utils locales tzdata

# Set the locale
RUN sed -i '/fr_FR.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

# install packages
RUN apt-get -y upgrade

RUN apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates nano curl wget2 unzip unrar sudo language-pack-fr

# clean up
RUN apt-get autoremove -y && apt-get clean && rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# https://github.com/just-containers/s6-overlay/releases
ARG S6_VERSION=2.2.0.3

# install s6-overlay
RUN file="/tmp/s6-overlay.tar.gz" && curl -fsSL -o "${file}" "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" && \
    tar xzf "${file}" -C / --exclude="./bin" && \
    tar xzf "${file}" -C /usr ./bin && \
    rm "${file}"


ARG BUILD_ARCHITECTURE
ENV BUILD_ARCHITECTURE=$BUILD_ARCHITECTURE