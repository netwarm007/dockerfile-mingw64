FROM ubuntu:latest
MAINTAINER Chen, Wenli <chenwenli@chenwenli.com>

WORKDIR /tmp/work
ENV 	PRJROOT=/tmp/work/w64 \
	TARGET=x86_64-w64-mingw32 
ENV 	PREFIX=${PRJROOT}/tools \
	BUILD=${PRJROOT}/build-tools 
ENV 	TARGET_PREFIX=${PREFIX}/${TARGET}
ENV	MAKEOPTS="-j4 --quiet"

COPY createdir.sh .

RUN \
	/bin/bash createdir.sh && rm createdir.sh

WORKDIR $BUILD

RUN apt-get -qq update && apt-get install --no-install-recommends -qqy \
	build-essential \
	ca-certificates \
	curl \
	tar \
	gzip \
	lzip \
 && rm -rf /var/lib/apt/lists/*

RUN curl -L http://ftp.gnu.org/gnu/binutils/binutils-2.27.tar.gz > binutils-2.27.tar.gz \
 && tar zxf binutils-2.27.tar.gz \
 && cd build-binutils \
 && ../binutils-2.27/configure --target=$TARGET --prefix=$PREFIX --with-sysroot=$PREFIX \
 && make \
 && make install \ 
 && cd $BUILD \ 
 && rm -rf build-binutils binutils-2.27 binutils-2.27.tar.gz

# mingw headers

RUN curl -L http://downloads.sourceforge.net/project/mingw-w64/mingw-w64/mingw-w64-release/mingw-w64-v5.0.0.tar.bz2 > mingw-w64-v5.0.0.tar.bz2 \
 && tar jxf mingw-w64-v5.0.0.tar.bz2 \
 && rm mingw-w64-v5.0.0.tar.bz2 \
 && mkdir -p $BUILD/build-mingw-w64-header/ \
 && cd $BUILD/build-mingw-w64-header/ \
 && ../mingw-w64-v5.0.0/configure --prefix=$TARGET_PREFIX --without-crt \
 && make \
 && make install \
 && cd $BUILD \
 && rm -rf build-mingw-w64-header

# gcc
RUN \
 curl -L http://ftp.tsukuba.wide.ad.jp/software/gcc/releases/gcc-6.3.0/gcc-6.3.0.tar.bz2 | tar jxf - \
 && ln -s $TARGET_PREFIX $PREFIX/mingw \
 && mkdir -p $TARGET_PREFIX/lib \
 && ln -s $TARGET_PREFIX/lib $TARGET_PREFIX/lib64 \
# gmp
 && curl -L https://gmplib.org/download/gmp/gmp-6.1.2.tar.lz | tar --lzip -xf -  \
 && mv gmp-6.1.2 gcc-6.3.0/gmp \
# mpc
 && curl -L ftp://ftp.gnu.org/gnu/mpc/mpc-1.0.3.tar.gz | tar zxf - \
 && mv mpc-1.0.3 gcc-6.3.0/mpc \
# mpfr
 && curl -L http://www.mpfr.org/mpfr-current/mpfr-3.1.5.tar.bz2 | tar jxf - \
 && mv mpfr-3.1.5 gcc-6.3.0/mpfr \
 && cd $BUILD/build-boot-gcc \
 && ../gcc-6.3.0/configure --target=$TARGET --prefix=$PREFIX --enable-languages=c,c++ \
 && make all-gcc \
 && make install-gcc \
 && cd $BUILD \
 && rm -rf build-boot-gcc

RUN \
 cd $BUILD/build-mingw-w64-crt \
 && ../mingw-w64-v5.0.0/configure --host=$TARGET --prefix=$TARGET_PREFIX --without-header --with-sysroot=$TARGET_PREFIX \
 && make \
 && make install \
 && cd $BUILD \
 && rm -rf build-mingw-w64-crt mingw-w64-v5.0.0

RUN \
 cd $BUILD/build-gcc \
 && ../gcc-6.3.0/configure --target=$TARGET --prefix=$PREFIX --enable-languages=c,c++ \
 && make all \
 && make install \
 && cd $BUILD \
 && rm -rf build-gcc gcc-6.3.0 \
 && cd / && rm -rf /tmp/work

ENV PATH=${PATH}:${PREFIX}/bin

CMD ["/bin/bash"]
