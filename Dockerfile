FROM balenalib/rpi-alpine-python:2.7.16-3.9-build as build

ARG OCTOPRINT_VERSION=1.4.0
ARG PYBONJOUR_URL=https://goo.gl/SxQZ06
ARG PYBONJOUR_VER=1.1.1

RUN set -xe \
    \
    && apk update \
    && apk upgrade \
    && apk add \
        avahi-compat-libdns_sd \
        build-base \
        cmake \
        lapack \
        libjpeg-turbo-dev \
        linux-headers \
        openssl \
        openssl-dev

RUN wget -qO- https://github.com/jacksonliam/mjpg-streamer/archive/master.tar.gz \
      | tar xz \
    && cd /mjpg-streamer-master/mjpg-streamer-experimental \
    && make \
    && make install

RUN wget -qO- $PYBONJOUR_URL > pybonjour-$PYBONJOUR_VER.tar.gz \
    && pip install pybonjour-$PYBONJOUR_VER.tar.gz

RUN wget -qO- https://github.com/foosel/OctoPrint/archive/$OCTOPRINT_VERSION.tar.gz \
      | tar xz \
    && cd /OctoPrint-$OCTOPRINT_VERSION \
    && pip install -r requirements.txt \
    && python setup.py install

RUN pip --version \
    && pip install https://github.com/amsbr/OctoPrint-EEPROM-Marlin/archive/master.zip \
    && pip install https://github.com/BillyBlaze/OctoPrint-TouchUI/archive/master.zip \
    && pip install https://github.com/bradcfisher/OctoPrint-ExcludeRegionPlugin/archive/master.zip \
    && pip install https://github.com/birkbjo/OctoPrint-Themeify/archive/master.zip \
    && pip install https://github.com/FormerLurker/Octolapse/archive/v0.3.4.zip \
    && pip install https://github.com/google/OctoPrint-HeaterTimeout/archive/master.zip \
    && pip install https://github.com/houseofbugs/OctoPrint-ExtraDistance/archive/master.zip \
    && pip install https://github.com/ieatacid/OctoPrint-GcodeEditor/archive/master.zip \
    && pip install https://github.com/imrahil/OctoPrint-NavbarTemp/archive/master.zip \
    && pip install https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/master.zip \
    && pip install https://github.com/jneilliii/OctoPrint-BLTouch/archive/master.zip \
    && pip install https://github.com/jneilliii/OctoPrint-FloatingNavbar/archive/master.zip \
    && pip install https://github.com/jneilliii/OctoPrint-TabOrder/archive/master.zip \
    && pip install https://github.com/jneilliii/OctoPrint-TPLinkSmartplug/archive/master.zip \
    && pip install https://github.com/ntoff/OctoPrint-Estop/archive/master.zip \
    && pip install https://github.com/OctoPrint/OctoPrint-FirmwareUpdater/archive/master.zip

FROM balenalib/rpi-alpine-python:2.7.16-3.9-run

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /mjpg-streamer-*/mjpg-streamer-experimental /opt/mjpg-streamer
COPY --from=build /OctoPrint-* /opt/octoprint

RUN set -xe \
    \
    && apk --no-cache add \
        avahi \
        avahi-compat-libdns_sd \
        avrdude \
        ffmpeg \
        haproxy \
        lapack \
        libjpeg \
    && pip --no-cache-dir install supervisor \
    && sed -i 's/#enable-dbus=yes/enable-dbus=no/g' /etc/avahi/avahi-daemon.conf

VOLUME /data
WORKDIR /data

EXPOSE 80
EXPOSE 5353/udp

COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY supervisord.conf /etc/supervisor/supervisord.conf

ENV CAMERA_DEV /dev/video0
ENV STREAMER_FLAGS -y -n

CMD ["/usr/local/bin/python", "/usr/local/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
