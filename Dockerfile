FROM cm2network/steamcmd:latest

USER root
RUN set -x \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests \
		libtext-csv-perl \
		libtext-csv-xs-perl \
		libipc-run3-perl \
	&& apt-get clean autoclean \
	&& apt-get autoremove -y \
	&& rm -rf /var/lib/apt/lists/*

USER steam

COPY load-mods.pl .
COPY current-modpack.csv .

ENTRYPOINT [ "perl", "load-mods.pl" ]

