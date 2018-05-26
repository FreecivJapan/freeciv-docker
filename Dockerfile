FROM centos
MAINTAINER Masaru Watanabe <sensunowatson@gmail.com>

# language config
RUN yum update -y
RUN yum -y install glibc-common
RUN localedef -v -c -i ja_JP -f UTF-8 ja_JP.UTF-8; echo "";

ENV LANG=ja_JP.UTF-8
RUN rm -f /etc/localtime
RUN ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

# install freeciv
RUN yum update -y
RUN yum install -y wget bzip2 gcc llibcurl libcurl-devel libtool \
	git gettext autoconf make automake atk pango zlib-devel gtk2-devel
RUN wget http://files.freeciv.org/stable/freeciv-2.5.11.tar.bz2 && \
	tar xf freeciv-2.5.11.tar.bz2 && \
	cd freeciv-2.5.11 && \
	./autogen.sh && make && make install && make clean && \
	cd ../ && rm -rf freeciv-2.5.11/ freeciv-2.5.11.tar.bz2
RUN yum clean all

# add execute user
RUN useradd freeciv
USER freeciv

# execute
EXPOSE 5556
ENTRYPOINT ["/usr/local/bin/freeciv-server"]
CMD ["-m", "-i", "fomalhaut-freeciv.jp", "-q", "1000", "-r", "/home/freeciv/start-command.serv", "-k"] 
