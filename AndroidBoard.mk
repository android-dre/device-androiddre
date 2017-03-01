#############################################################################
# 				Build kernel				    #
#############################################################################
ifneq ($(TARGET_PREBUILT_KERNEL),)
$(error TARGET_PREBUILT_KERNEL defined but AndroidIA kernels build from source)
endif

TARGET_KERNEL_SRC ?= kernel/androiddre

TARGET_KERNEL_ARCH := arm
TARGET_KERNEL_CONFIG ?= imx6_defconfig
ADDITIONAL_DEFAULT_PROPERTIES += ro.boot.moduleslocation=/vendor/lib/modules

KERNEL_CONFIG_DIR := device/nxp/imx6q/android_dre

KERNEL_NAME := zImage

# Set the output for the kernel build products.
KERNEL_OUT := $(abspath $(TARGET_OUT_INTERMEDIATES)/kernel)
KERNEL_BIN := $(KERNEL_OUT)/arch/$(TARGET_KERNEL_ARCH)/boot/$(KERNEL_NAME)
KERNEL_MODULES_INSTALL := $(TARGET_OUT)/lib/modules

KERNELRELEASE = $(shell cat $(KERNEL_OUT)/include/config/kernel.release)

KERNEL_CROSS_TOOLCHAIN := `pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
KERNEL_CFLAGS := -mno-android
#KERNEL_ENV := ARCH=arm CROSS_COMPILE=$(KERNEL_CROSS_TOOLCHAIN) LOADADDR=$(LOAD_KERNEL_ENTRY) $(KERNEL_CFLAGS)

# Build for Device tree
DT_NAME := imx6q-androiddre.dtb
DT_BIN := $(KERNEL_OUT)/arch/$(TARGET_KERNEL_ARCH)/boot/dts/$(DT_NAME)


build_kernel := +$(MAKE) -C $(TARGET_KERNEL_SRC) \
		O=$(KERNEL_OUT) \
		ARCH=$(TARGET_KERNEL_ARCH) \
		CROSS_COMPILE="$(KERNEL_CROSS_TOOLCHAIN)" \
		LD="$(KERNEL_CROSS_TOOLCHAIN)ld.bfd" \
		KCFLAGS="$(KERNEL_CFLAGS)" \
		KAFLAGS="$(KERNEL_AFLAGS)" \
		$(if $(SHOW_COMMANDS),V=1) \
		INSTALL_MOD_PATH=$(abspath $(TARGET_OUT))

build_dt := +$(MAKE) -C $(TARGET_KERNEL_SRC) \
		O=$(KERNEL_OUT) \
		ARCH=$(TARGET_KERNEL_ARCH) \
		CROSS_COMPILE=$(KERNEL_CROSS_TOOLCHAIN) \
		LD=$(KERNEL_CROSS_TOOLCHAIN)ld.bfd \
		KCFLAGS=$(KERNEL_CFLAGS) \
		KAFLAGS="$(KERNEL_AFLAGS)" \
		$(if $(SHOW_COMMANDS),V=1)

KERNEL_CONFIG_FILE := device/nxp/imx6q/android_dre/$(TARGET_KERNEL_CONFIG)

KERNEL_CONFIG := $(KERNEL_OUT)/.config
$(KERNEL_CONFIG): $(KERNEL_CONFIG_FILE)
	$(hide) mkdir -p $(@D) && cat $(wildcard $^) > $@
	$(build_kernel) oldnoconfig

# Produces the actual kernel image!
$(PRODUCT_OUT)/kernel: $(KERNEL_CONFIG) | $(ACP)
	$(build_kernel) $(KERNEL_NAME) modules
	$(hide) $(ACP) -fp $(KERNEL_BIN) $@
	$(build_dt) $(DT_NAME)
	$(hide) install -D $(DT_BIN) $(PRODUCT_OUT)/$(DT_NAME)

ALL_EXTRA_MODULES := $(patsubst %,$(TARGET_OUT_INTERMEDIATES)/kmodule/%,$(TARGET_EXTRA_KERNEL_MODULES))
$(ALL_EXTRA_MODULES): $(TARGET_OUT_INTERMEDIATES)/kmodule/%: $(PRODUCT_OUT)/kernel
	@echo Building additional kernel module $*
	$(build_kernel) M=$(abspath $@) modules

# Copy modules in directory pointed by $(KERNEL_MODULES_ROOT)
# First copy modules keeping directory hierarchy lib/modules/`uname-r`for libkmod
# Second, create flat hierarchy for insmod linking to previous hierarchy
$(KERNEL_MODULES_INSTALL): $(PRODUCT_OUT)/kernel $(ALL_EXTRA_MODULES)
	$(hide) rm -rf $(TARGET_OUT)/lib/modules
	$(build_kernel) modules_install
	$(hide) for kmod in "$(TARGET_EXTRA_KERNEL_MODULES)" ; do \
		echo Installing additional kernel module $${kmod} ; \
		$(subst +,,$(subst $(hide),,$(build_kernel))) M=$(abspath $(TARGET_OUT_INTERMEDIATES))/$${kmod}.kmodule modules_install ; \
	done
	$(hide) rm -f $(TARGET_OUT)/lib/modules/*/{build,source}
	$(hide) rm -rf $(PRODUCT_OUT)/system/vendor/lib/modules
	$(hide) mkdir -p $(PRODUCT_OUT)/system/vendor/lib/
	$(hide) cp -rf $(TARGET_OUT)/lib/modules/$(KERNELRELEASE)/ $(PRODUCT_OUT)/system/vendor/lib/modules
	$(hide) touch $@

# Makes sure any built modules will be included in the system image build.
ALL_DEFAULT_INSTALLED_MODULES += $(KERNEL_MODULES_INSTALL)

installclean: FILES += $(KERNEL_OUT) $(PRODUCT_OUT)/kernel

.PHONY: kernel
kernel: $(PRODUCT_OUT)/kernel

#############################################################################
# 				Build bootloader			    #
#############################################################################
.PHONY: bootloader
BOOTLOADER_DEVICE_NAME ?= android_dre
TARGET_BOOTLOADER_SRC ?= bootable/bootloader/ubootfsl
TARGET_BOOTLOADER_ARCH := arm
TARGET_BOOTLOADER_CONFIG ?= mx6qsabresdandroid_defconfig
BOOTLOADER_CONFIG_DIR := device/nxp/imx6q/android_dre
BOOTLOADER_NAME := u-boot.imx
BOOTLOADER_OUT := $(abspath $(TARGET_OUT_INTERMEDIATES)/uboot)
BOOTLOADER_BIN := $(BOOTLOADER_OUT)/$(BOOTLOADER_NAME)
BOOTLOADER_CROSS_COMPILE_TOOLCHAIN := `pwd`/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

build_bootloader := +$(MAKE) -C $(TARGET_BOOTLOADER_SRC) \
		O=$(BOOTLOADER_OUT) \
                ARCH=$(TARGET_BOOTLOADER_ARCH) \
                CROSS_COMPILE=$(BOOTLOADER_CROSS_COMPILE_TOOLCHAIN) \
                LD=$(BOOTLOADER_CROSS_COMPILE_TOOLCHAIN)ld.bfd \
		$(if $(SHOW_COMMANDS),V=1)

BOOTLOADER_CONFIG_FILE := device/nxp/imx6q/android_dre/$(TARGET_BOOTLOADER_CONFIG)

BOOTLOADER_CONFIG := $(BOOTLOADER_OUT)/.config
$(BOOTLOADER_CONFIG): $(BOOTLOADER_CONFIG_FILE)
	$(hide) mkdir -p $(@D) && cat $(wildcard $^) > $@
	$(build_bootloader) oldnoconfig

.PHONY: $(PRODUCT_OUT)/u-boot_$(BOOTLOADER_DEVICE_NAME).imx
bootloader: $(PRODUCT_OUT)/u-boot_$(BOOTLOADER_DEVICE_NAME).imx
$(PRODUCT_OUT)/u-boot_$(BOOTLOADER_DEVICE_NAME).imx: $(BOOTLOADER_CONFIG) | $(ACP)
	$(build_bootloader)
	$(hide) $(ACP) -fp $(BOOTLOADER_BIN) $@

############################################################################

############################################################################

############################################################################
               
             
           























