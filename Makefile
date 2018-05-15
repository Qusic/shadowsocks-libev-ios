SDK = iphoneos
ARCH = arm64
HOST = aarch64-apple-darwin
SDKROOT = $(shell xcrun --sdk $(SDK) --show-sdk-path)

export CC = $(shell xcrun -find -sdk $(SDK) clang)
export CXX = $(shell xcrun -find -sdk $(SDK) clang++)
export CFLAGS = -arch $(ARCH) -isysroot $(SDKROOT) -isystem $(PWD)/include
export LDFLAGS = -arch $(ARCH) -isysroot $(SDKROOT)

all: build

shadowsocks:
	git clone git@github.com:shadowsocks/shadowsocks-libev.git $@ || git -C $@ pull

openssl:
	git clone git@github.com:x2on/OpenSSL-for-iPhone.git $@ || git -C $@ pull

include:
	mkdir -p $@ && cp $(shell xcrun --sdk iphonesimulator --show-sdk-path)/usr/include/crt_externs.h $@

update:
	make --always-make shadowsocks openssl include

build: shadowsocks openssl include
	cd openssl \
		&& ./build-libssl.sh
	cd shadowsocks \
		&& ./configure --prefix=$(PWD)/stage --host=$(HOST) --with-openssl=$(PWD)/openssl \
		&& make \
		&& find src -type f -perm -111 -exec ldid -S {} +

package: control stage
	dir=layout/DEBIAN && mkdir -p $$dir \
		&& cp control $$dir
	dir=layout/usr/bin && mkdir -p $$dir \
		&& cp stage/bin/* $$dir
	find layout -name .DS_Store -delete
	dpkg-deb -b -Zgzip layout shadowsocks.deb

clean:
	rm -rf stage layout

reset:
	rm -rf shadowsocks openssl include stage layout

.PHONY: all update build package clean reset
