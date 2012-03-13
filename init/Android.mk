# Copyright (C) 2011 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ifneq ($(filter qss,$(TARGET_DEVICE)),)

LOCAL_PATH := $(call my-dir)

TARGET_QSSBOOT_OUT := $(PRODUCT_OUT)/qssboot
TARGET_QSSBOOT_ROOT_OUT := $(TARGET_QSSBOOT_OUT)/root

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := eng
LOCAL_C_INCLUDES += system/core/init
LOCAL_SRC_FILES := init_ext.c

# should match TARGET_INIT_EXT_LIB set in BoardConfig.mk
LOCAL_MODULE := libinit_ext_qss

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

# -----------------------------------------------------------------
# QSS boot image
#
#  - Recovery function is embedded within boot image

ifeq (,$(filter true, $(TARGET_NO_RECOVERY) $(BUILD_TINY_ANDROID)))

boot_ramdisk_cpio := $(PRODUCT_OUT)/ramdisk-qssboot.cpio
boot_ramdisk := $(PRODUCT_OUT)/ramdisk-qssboot.img
boot_kernel := $(INSTALLED_KERNEL_TARGET)

recovery_initrc := $(call include-path-for, recovery)/etc/init.rc
recovery_initrc_private := $(TARGET_DEVICE_DIR)/recovery.$(TARGET_DEVICE).rc
recovery_build_prop := $(INSTALLED_BUILD_PROP_TARGET)
recovery_binary := $(call intermediates-dir-for,EXECUTABLES,recovery)/recovery
recovery_resources_common := $(call include-path-for, recovery)/res
recovery_resources_private := $(strip $(wildcard $(TARGET_DEVICE_DIR)/recovery/res))
recovery_resource_deps := $(shell find $(recovery_resources_common) \
  $(recovery_resources_private) -type f)
recovery_fstab := $(strip $(wildcard $(TARGET_DEVICE_DIR)/recovery.fstab))

ifeq ($(recovery_resources_private),)
  $(info No private recovery resources for TARGET_DEVICE $(TARGET_DEVICE))
endif

ifeq ($(recovery_fstab),)
  $(info No recovery.fstab for TARGET_DEVICE $(TARGET_DEVICE))
endif

$(boot_ramdisk_cpio): $(MKBOOTFS) \
		$(INSTALLED_RAMDISK_TARGET) \
		$(INSTALLED_BOOTIMAGE_TARGET) \
		$(recovery_binary) $(recovery_initrc) \
		$(recovery_build_prop) $(recovery_resource_deps) \
		$(recovery_fstab) \
		$(RECOVERY_INSTALL_OTA_KEYS) \
		recoveryimage
	$(call pretty," ----- Making QSS boot image ------ ")
	rm -rf $(TARGET_QSSBOOT_OUT)
	mkdir -p $(TARGET_QSSBOOT_OUT)
	mkdir -p $(TARGET_QSSBOOT_ROOT_OUT)
	mkdir -p $(TARGET_QSSBOOT_ROOT_OUT)/system/etc
	$(call pretty,"Copying baseline ramdisk...")
	cp -R $(TARGET_ROOT_OUT) $(TARGET_QSSBOOT_OUT)
	$(call pretty,"Modifying ramdisk contents...")
	cp -f $(recovery_initrc) $(TARGET_QSSBOOT_ROOT_OUT)/recovery.rc
	cp -f $(recovery_initrc_private) $(TARGET_QSSBOOT_ROOT_OUT)/
	cp -f $(recovery_binary) $(TARGET_QSSBOOT_ROOT_OUT)/sbin/
	cp -rf $(recovery_resources_common) $(TARGET_QSSBOOT_ROOT_OUT)/
	$(foreach item,$(recovery_resources_private), \
	  cp -rf $(item) $(TARGET_QSSBOOT_ROOT_OUT)/)
	$(foreach item,$(recovery_fstab), \
	  cp -f $(item) $(TARGET_QSSBOOT_ROOT_OUT)/system/etc/recovery.fstab)
	cp $(RECOVERY_INSTALL_OTA_KEYS) $(TARGET_QSSBOOT_ROOT_OUT)/res/keys
	cat $(INSTALLED_DEFAULT_PROP_TARGET) > $(TARGET_QSSBOOT_ROOT_OUT)/default.prop
	echo "ro.product.device=qss" >> $(TARGET_QSSBOOT_ROOT_OUT)/default.prop
	$(call pretty," ----- Made QSS ramdisk : $@ ----- ")
	$(MKBOOTFS) $(TARGET_QSSBOOT_ROOT_OUT) > $@

$(boot_ramdisk): $(boot_ramdisk_cpio) $(MINIGZIP)
	$(call pretty," ----- Made QSS compressed ramdisk : $@ ----- ")
	cat $(boot_ramdisk_cpio) | $(MINIGZIP) > $@

ifneq ($(strip $(TARGET_NO_KERNEL)),true)

INSTALLED_QSSBOOTIMAGE_TARGET := $(PRODUCT_OUT)/qssboot.img

INTERNAL_QSSBOOTIMAGE_ARGS := \
	$(addprefix --second ,$(INSTALLED_2NDBOOTLOADER_TARGET)) \
	--kernel $(boot_kernel) \
	--ramdisk $(boot_ramdisk)

# Assumes this has already been stripped
ifdef BOARD_KERNEL_CMDLINE
  INTERNAL_QSSBOOTIMAGE_ARGS += --cmdline "$(BOARD_KERNEL_CMDLINE)"
endif
ifdef BOARD_KERNEL_BASE
  INTERNAL_QSSBOOTIMAGE_ARGS += --base $(BOARD_KERNEL_BASE)
endif
BOARD_KERNEL_PAGESIZE := $(strip $(BOARD_KERNEL_PAGESIZE))
ifdef BOARD_KERNEL_PAGESIZE
  INTERNAL_QSSBOOTIMAGE_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
endif

$(INSTALLED_QSSBOOTIMAGE_TARGET): $(MKBOOTIMG) $(boot_kernel) $(boot_ramdisk) \
		$(INSTALLED_2NDBOOTLOADER_TARGET)
	$(MKBOOTIMG) $(INTERNAL_QSSBOOTIMAGE_ARGS) --output $@
	$(call pretty," ----- Made QSS boot image : $@ ----- ")
	$(hide) $(call assert-max-image-size,$@,$(BOARD_BOOTIMAGE_PARTITION_SIZE),raw)

else
INSTALLED_QSSBOOTIMAGE_TARGET := $(boot_ramdisk)
endif

else
INSTALLED_QSSBOOTIMAGE_TARGET :=
endif

.PHONY: qssbootimage
qssbootimage: $(INSTALLED_QSSBOOTIMAGE_TARGET)

endif
