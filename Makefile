.PHONY: all buildroot

PATH := $(PATH):$(shell pwd)/crosstool/bin

CROSSTOOL=crosstool-ng-1.19.0

all: buildroot

.downloaded_ct_ng:
	wget -c http://crosstool-ng.org/download/crosstool-ng/${CROSSTOOL}.tar.bz2
	touch .downloaded_ct_ng

.extracted_ct_ng: .downloaded_ct_ng
	tar -xvjf ${CROSSTOOL}.tar.bz2
	touch .extracted_ct_ng

.installed_ct_ng: .extracted_ct_ng
	cd ${CROSSTOOL}&&./configure --prefix=$(shell pwd)/crosstool
	sed -i "s/.*Recursion detected.*//g" ${CROSSTOOL}/Makefile
	cd ${CROSSTOOL}&&make
	cd ${CROSSTOOL}&&make install
	touch .installed_ct_ng

.installed_xtools: .installed_ct_ng
	mkdir -p ct-ng-build
	cd ct-ng-build&&ct-ng arm-unknown-linux-gnueabi
	cd ct-ng-build&&cat ../ng-config > .config
	cd ct-ng-build&&ct-ng build
	touch .installed_xtools

buildroot-a13-olinuxino:
	git clone https://github.com/mireq/buildroot-a13-olinuxino

.configured_buildroot: buildroot-a13-olinuxino .installed_xtools
	cat buildroot-a13-olinuxino/configs/a13_olinuxino_defconfig > buildroot-a13-olinuxino/configs/a13_olinuxino_crossng_defconfig
	cat buildroot-config >> buildroot-a13-olinuxino/configs/a13_olinuxino_crossng_defconfig
	echo "BR2_TOOLCHAIN_EXTERNAL_PATH=\"$(shell pwd)/x-tools/arm-cortex_a8-linux-gnueabi\"" >> buildroot-a13-olinuxino/configs/a13_olinuxino_crossng_defconfig
	touch .configured_buildroot

.installed_buildroot_stage1: buildroot-a13-olinuxino .configured_buildroot
	make -C buildroot-a13-olinuxino a13_olinuxino_crossng_defconfig
	make -C buildroot-a13-olinuxino
	touch .installed_buildroot_stage1

.installed_buildroot_stage2: .installed_buildroot_stage1
	rm -f buildroot-a13-olinuxino/output/build/linux-HEAD/.stamp_{built,target_installed,images_installed}
	cat linux-config > buildroot-a13-olinuxino/output/build/linux-HEAD/.config
	make -C buildroot-a13-olinuxino
	touch .installed_buildroot_stage2

buildroot: .installed_buildroot_stage2 .installed_buildroot_stage2
	make -C buildroot-a13-olinuxino

clean:
	rm -rf ${CROSSTOOL}
	rm -f ${CROSSTOOL}.tar.bz2
