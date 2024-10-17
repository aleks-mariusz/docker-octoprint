FROM balenalib/rpi-alpine-python:3.7.16-3.16-build as build

ARG OCTOPRINT_VERSION=1.10.2

ARG OCTOPRINT_PLUGIN_AUTOTERMINALINPUT_VERSION=master
ARG OCTOPRINT_PLUGIN_BEDLEVELVISUALIZER_VERSION=master
ARG OCTOPRINT_PLUGIN_BLTOUCH_VERSION=0.3.4
ARG OCTOPRINT_PLUGIN_EEPROMMARLIN_VERSION=3.3.0
ARG OCTOPRINT_PLUGIN_ESTOP_VERSION=1.0.6
ARG OCTOPRINT_PLUGIN_EXCLUDEREGION_VERSION=0.3.2
ARG OCTOPRINT_PLUGIN_EXTRADISTANCE_VERSION=0.1.1
ARG OCTOPRINT_PLUGIN_FIRMWAREUPDATER_VERSION=1.14.1
ARG OCTOPRINT_PLUGIN_FLOATINGNAVGAR_VERSION=0.3.7
ARG OCTOPRINT_PLUGIN_GCODEEDITOR_VERSION=0.2.14
ARG OCTOPRINT_PLUGIN_HEATERTIMEOUT_VERSION=master
ARG OCTOPRINT_PLUGIN_NAVBARTEMP_VERSION=0.15
ARG OCTOPRINT_PLUGIN_OCTOLAPSE_VERSION=0.4.5
ARG OCTOPRINT_PLUGIN_TABORDER_VERSION=0.5.12
ARG OCTOPRINT_PLUGIN_THEMIFY_VERSION=1.2.2

RUN set -xe \
    \
    && apk update \
    && apk upgrade \
    && apk add \
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

RUN wget -qO- https://github.com/foosel/OctoPrint/archive/$OCTOPRINT_VERSION.tar.gz \
      | tar xz \
    && cd /OctoPrint-$OCTOPRINT_VERSION \
    && pip install -r requirements.txt \
    && python setup.py install

RUN pip --version \
    && pip install https://github.com/jneilliii/OctoPrint-BedLevelVisualizer/archive/$OCTOPRINT_PLUGIN_BEDLEVELVISUALIZER_VERSION.zip \
    && pip install https://github.com/jneilliii/OctoPrint-BLTouch/archive/$OCTOPRINT_PLUGIN_BLTOUCH_VERSION.zip \
    && pip install https://github.com/cp2004/OctoPrint-EEPROM-Marlin/archive/$OCTOPRINT_PLUGIN_EEPROMMARLIN_VERSION.zip \
    && pip install https://github.com/Sebclem/OctoPrint-SimpleEmergencyStop/archive/$OCTOPRINT_PLUGIN_ESTOP_VERSION.zip \
    && pip install https://github.com/bradcfisher/OctoPrint-ExcludeRegionPlugin/archive/$OCTOPRINT_PLUGIN_EXCLUDEREGION_VERSION.zip \
    && pip install https://github.com/scmanjarrez/OctoPrint-ExtraDistance/archive/$OCTOPRINT_PLUGIN_EXTRADISTANCE_VERSION.zip \
    && pip install https://github.com/OctoPrint/OctoPrint-FirmwareUpdater/archive/$OCTOPRINT_PLUGIN_FIRMWAREUPDATER_VERSION.zip \
    && pip install https://github.com/jneilliii/OctoPrint-FloatingNavbar/archive/$OCTOPRINT_PLUGIN_FLOATINGNAVGAR_VERSION.zip \
    && pip install https://github.com/ieatacid/OctoPrint-GcodeEditor/archive/$OCTOPRINT_PLUGIN_GCODEEDITOR_VERSION.zip \
    && pip install https://github.com/google/OctoPrint-HeaterTimeout/archive/$OCTOPRINT_PLUGIN_HEATERTIMEOUT_VERSION.zip \
    && pip install https://github.com/imrahil/OctoPrint-NavbarTemp/archive/$OCTOPRINT_PLUGIN_NAVBARTEMP_VERSION.zip \
    && pip install https://github.com/jneilliii/OctoPrint-AutoTerminalInput/archive/$OCTOPRINT_PLUGIN_AUTOTERMINALINPUT_VERSION.zip \
    && pip install https://github.com/FormerLurker/Octolapse/archive/v$OCTOPRINT_PLUGIN_OCTOLAPSE_VERSION.zip \
    && pip install https://github.com/jneilliii/OctoPrint-TabOrder/archive/$OCTOPRINT_PLUGIN_TABORDER_VERSION.zip \
    && pip install https://github.com/birkbjo/OctoPrint-Themeify/archive/v$OCTOPRINT_PLUGIN_THEMIFY_VERSION.zip \
    && pip install https://github.com/jneilliii/OctoPrint-TPLinkSmartplug/archive/master.zip

FROM balenalib/rpi-alpine-python:3.7.16-3.16-run

COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/lib /usr/local/lib
COPY --from=build /mjpg-streamer-*/mjpg-streamer-experimental /opt/mjpg-streamer
COPY --from=build /OctoPrint-* /opt/octoprint

RUN set -xe \
    \
    && apk --no-cache add \
        avrdude \
        ffmpeg \
        haproxy \
        lapack \
        libjpeg \
    && pip --no-cache-dir install supervisor

VOLUME /data
WORKDIR /data

EXPOSE 80
EXPOSE 5353/udp

COPY haproxy.cfg /etc/haproxy/haproxy.cfg
COPY supervisord.conf /etc/supervisor/supervisord.conf

ENV CAMERA_DEV /dev/video0
ENV STREAMER_FLAGS -y -n

CMD ["/usr/local/bin/python", "/usr/local/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
