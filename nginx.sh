#!/usr/bin/env bash
 
# OS information

export OS=$(lsb_release -si)
export ARCH=$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')
export VER=$(lsb_release -sr)


# latest stable versions of package

export LUA_VERSION=LuaJIT-2.0.4

export NGINX_VERSION=1.10.2

export VERSION_PCRE=pcre-8.39

export VERSION_LIBRESSL=libressl-2.4.4

export VERSION_NGINX_LUA=0.10.7

export VERSION_NGINX=nginx-$NGINX_VERSION

export VERSION_NGINX_HEADERS_MORE=0.32

 # tell nginx's build system where to find LuaJIT 2.1:
 export LUAJIT_LIB=/usr/local/lib
 export LUAJIT_INC=/usr/local/include/luajit-2.0


 
export SOURCE_LIBRESSL=http://ftp.openbsd.org/pub/OpenBSD/LibreSSL/
export SOURCE_PCRE=ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/
export SOURCE_NGINX=http://nginx.org/download/
export SOURCE_BROTLI=https://github.com/google/ngx_brotli.git
export SOURCE_NGINX_LUA=https://github.com/openresty/lua-nginx-module/archive/
export SOURCE_LUAJIT=http://luajit.org/download/
export SOURCE_HEADERS_MORE=https://github.com/openresty/headers-more-nginx-module/archive/


NUM_PROC=$(grep -c ^processor /proc/cpuinfo)

# install requirments
if [ $OS == 'Debian' ]; then
    sudo apt-get -y install curl wget build-essential libgeoip-dev checkinstall git libgd2-xpm-dev
elif [ $OS == 'Ubuntu' ];then
    sudo apt-get -y install curl wget build-essential libgeoip-dev checkinstall git libgd2-xpm-dev
else
	echo "$OS not support"
	exit 1 
fi

 

# clean
rm -rf build
mkdir build

	


echo "Downloading source code..."
wget -P ./build $SOURCE_PCRE$VERSION_PCRE.tar.gz
wget -P ./build $SOURCE_LIBRESSL$VERSION_LIBRESSL.tar.gz
wget -P ./build $SOURCE_NGINX$VERSION_NGINX.tar.gz
wget -P ./build ${SOURCE_NGINX_LUA}v${VERSION_NGINX_LUA}.tar.gz
wget -P ./build $SOURCE_LUAJIT$LUA_VERSION.tar.gz
wget -P ./build ${SOURCE_HEADERS_MORE}v${VERSION_NGINX_HEADERS_MORE}.tar.gz


 


echo "Extract Packages..."
cd build
tar xzf $VERSION_NGINX.tar.gz
tar xzf $VERSION_LIBRESSL.tar.gz
tar xzf $VERSION_PCRE.tar.gz
tar xzf v$VERSION_NGINX_LUA.tar.gz
tar xzf $LUA_VERSION.tar.gz
tar xzf v$VERSION_NGINX_HEADERS_MORE.tar.gz
cd ../


# set where LibreSSL and nginx will be built

export BPATH=$(pwd)/build
export STATICLIBSSL=$BPATH/$VERSION_LIBRESSL
export LUAJITPATH=$BPATH/$LUA_VERSION


# build luajit
echo "Build LuaJIT & Install"
cd $LUAJITPATH


make -j $NB_PROC && sudo make install


# build static LibreSSL
echo "Configure & Build LibreSSL"


cd $STATICLIBSSL
./configure LDFLAGS=-lrt --prefix=${STATICLIBSSL}/.openssl/ && make install-strip -j $NB_PROC

 

echo "Configure & Build Nginx"
cd $BPATH/$VERSION_NGINX



mkdir -p $BPATH/nginx
./configure  --with-openssl=$STATICLIBSSL \
--with-ld-opt="-Wl,-rpath,$LUAJIT_LIB,-lrt" \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--http-log-path=/var/log/nginx/access.log \
--with-pcre=$BPATH/$VERSION_PCRE \
--with-http_ssl_module \
--with-http_v2_module \
--with-file-aio \
--with-ipv6 \
--with-http_gzip_static_module \
--with-http_stub_status_module \
--without-mail_pop3_module \
--without-mail_smtp_module \
--without-mail_imap_module \
--with-http_image_filter_module \
 --lock-path=/var/lock/nginx.lock \
 --pid-path=/run/nginx.pid \
 --http-client-body-temp-path=/var/lib/nginx/body \
 --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
 --http-proxy-temp-path=/var/lib/nginx/proxy \
 --http-scgi-temp-path=/var/lib/nginx/scgi \
 --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
 --with-pcre-jit \
 --with-http_stub_status_module \
 --with-http_realip_module \
 --with-http_auth_request_module \
 --with-http_addition_module \
 --with-http_geoip_module \
 --with-http_gzip_static_module \
 --add-module=$BPATH/lua-nginx-module-$VERSION_NGINX_LUA
 --add-module=$BPATH/headers-more-nginx-module-$VERSION_NGINX_HEADERS_MORE

 
touch $STATICLIBSSL/.openssl/include/openssl/ssl.h
make -j $NUM_PROC && sudo checkinstall --pkgname="nginx-custom" --pkgversion="$NGINX_VERSION" \
--provides="nginx" --requires="libc6, libpcre3, zlib1g" --strip=yes \
--stripso=yes --backup=yes -y --install=yes
 
echo "Done."
