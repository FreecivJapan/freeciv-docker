FROM centos
MAINTAINER Masaru Watanabe <sensunowatson@gmail.com>

# install freeciv
RUN yum install -y wget bzip2 gcc llibcurl libcurl-devel libtool \
	git gettext autoconf make automake atk pango zlib-devel gtk2-devel
RUN wget http://files.freeciv.org/stable/freeciv-2.5.11.tar.bz2 && \
	tar xf freeciv-2.5.11.tar.bz2 && \
	cd freeciv-2.5.11 && \
	./autogen.sh && make && make install && make clean && \
	cd ../ && rm -rf freeciv-2.5.11/ freeciv-2.5.11.tar.bz2
RUN yum clean all

# change lang japanese
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
RUN echo 'ZONE="Asia/Tokyo"' > /etc/sysconfig/clock
RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# add execute user
RUN useradd freeciv
USER freeciv

# execute
EXPOSE 5556
CMD ["/usr/local/bin/freeciv-server", "-m", "-i fomalhaut-freeciv.jp", "-q 1000", "-r /home/freeciv/start-command.serv", "-k"] 
