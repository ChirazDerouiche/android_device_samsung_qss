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

LOCAL_PATH:= $(call my-dir)

TARGET_QSSRECOVERY_OUT := $(PRODUCT_OUT)/qssrecovery
TARGET_QSSRECOVERY_ROOT_OUT := $(TARGET_QSSRECOVERY_OUT)/root

include $(CLEAR_VARS)

LOCAL_MODULE_TAGS := eng
LOCAL_C_INCLUDES += bootable/recovery
LOCAL_SRC_FILES := recovery_ui.c

# should match TARGET_RECOVERY_UI_LIB set in BoardConfig.mk
LOCAL_MODULE := librecovery_ui_qss

include $(BUILD_STATIC_LIBRARY)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := kicker.c

LOCAL_MODULE := kicker

LOCAL_FORCE_STATIC_EXECUTABLE := true

LOCAL_STATIC_LIBRARIES := libcutils libc

LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_QSSRECOVERY_OUT)

include $(BUILD_EXECUTABLE)

include $(CLEAR_VARS)

# -----------------------------------------------------------------
# QSS recovery image
#
#  - This recovery image just kicker for actual recovery function
#    reside inside boot image, this step required since the boot-
#    loader param is in the BML partition and it is required to
#    access those param to set bootmode parameter. Since the main
#    boot image cannot do that so we do it here.

ifeq (,$(filter true, $(TARGET_NO_RECOVERY) $(BUILD_TINY_ANDROID)))

recovery_ramdisk_cpio := $(PRODUCT_OUT)/ramdisk-qssrecovery.cpio
recovery_ramdisk := $(PRODUCT_OUT)/ramdisk-qssrecovery.img
recovery_modules := $(TARGET_DEVICE_DIR)/recovery/modules
kicker_binary := $(call intermediates-dir-for,EXECUTABLES,kicker)/kicker

$(recovery_ramdisk_cpio): $(kicker_binary)
	$(call pretty," ----- Making QSS recovery image ------ ")
	rm -rf $(TARGET_QSSRECOVERY_OUT)
	mkdir -p $(TARGET_QSSRECOVERY_OUT)
	mkdir -p $(TARGET_QSSRECOVERY_ROOT_OUT)
	mkdir -p $(TARGET_QSSRECOVERY_ROOT_OUT)/dev
	mkdir -p $(TARGET_QSSRECOVERY_ROOT_OUT)/param
	cp -f $(kicker_binary) $(TARGET_QSSRECOVERY_ROOT_OUT)/init
	cp -rf $(recovery_modules) $(TARGET_QSSRECOVERY_ROOT_OUT)/modules
	$(call pretty," ----- Made QSS ramdisk : $@ ----- ")
	$(MKBOOTFS) $(TARGET_QSSRECOVERY_ROOT_OUT) > $@

$(recovery_ramdisk): $(recovery_ramdisk_cpio) $(MINIGZIP)
	$(call pretty," ----- Made QSS compressed ramdisk : $@ ----- ")
	cat $(recovery_ramdisk_cpio) | $(MINIGZIP) > $@

ifneq ($(strip $(TARGET_NO_KERNEL)),true)

INSTALLED_QSSRECOVERYIMAGE_TARGET := $(PRODUCT_OUT)/qssrecovery.img

recovery_kernel := $(INSTALLED_KERNEL_TARGET)

INTERNAL_QSSRECOVERYIMAGE_ARGS := \
	$(addprefix --second ,$(INSTALLED_2NDBOOTLOADER_TARGET)) \
	--kernel $(recovery_kernel) \
	--ramdisk $(recovery_ramdisk)

# Assumes this has already been stripped
ifdef BOARD_KERNEL_CMDLINE
  INTERNAL_QSSRECOVERYIMAGE_ARGS += --cmdline "$(BOARD_KERNEL_CMDLINE)"
endif
ifdef BOARD_KERNEL_BASE
  INTERNAL_QSSRECOVERYIMAGE_ARGS += --base $(BOARD_KERNEL_BASE)
endif
BOARD_KERNEL_PAGESIZE := $(strip $(BOARD_KERNEL_PAGESIZE))
ifdef BOARD_KERNEL_PAGESIZE
  INTERNAL_QSSRECOVERYIMAGE_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
endif

$(INSTALLED_QSSRECOVERYIMAGE_TARGET): $(recovery_ramdisk) $(recovery_kernel) $(MKBOOTIMG) \
		$(INSTALLED_2NDBOOTLOADER_TARGET)
	$(MKBOOTIMG) $(INTERNAL_QSSRECOVERYIMAGE_ARGS) --output $@
	$(call pretty," ----- Made QSS recovery image : $@ ----- ")
	$(hide) $(call assert-max-image-size,$@,$(BOARD_RECOVERY_PARTITION_SIZE),raw)

else
INSTALLED_QSSRECOVERYIMAGE_TARGET := $(recovery_ramdisk)
endif

else
INSTALLED_QSSRECOVERYIMAGE_TARGET :=
endif

.PHONY: qssrecoveryimage
qssrecoveryimage: $(INSTALLED_QSSRECOVERYIMAGE_TARGET)

endif
