#
# Copyright (C) 2011 The Android Open-Source Project
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
#

# This file includes all definitions that apply to ALL qss devices, and
# are also specific to qss devices
#
# Everything in this directory will become public

ifeq ($(TARGET_PREBUILT_KERNEL),)
LOCAL_KERNEL := device/qss/kernel
else
LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

DEVICE_PACKAGE_OVERLAYS := device/qss/overlay

PRODUCT_AAPT_CONFIG := normal hdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi

PRODUCT_PACKAGES := \
    lights.qss \
    hwcomposer.qss \
    charger \
    charger_res_images

#PRODUCT_PACKAGES += \
#    sensors.qss

PRODUCT_PACKAGES += \
    audio.primary.qss \
    audio.a2dp.default \
    libaudioutils

PRODUCT_PACKAGES += \
    libstagefrighthw \
    libLIMOMX_Core \
    libLIMOMX_Component.ffmpeg.mux \
    libLIMOMX_Component.ffmpeg.demux \
    libLIMOMX_Component.ffmpeg.vdec \
    libLIMOMX_Component.ffmpeg.adec \
    libLIMOMX_Component.ffmpeg.venc \
    libLIMOMX_Component.ffmpeg.aenc

ifneq ($(strip $(TARGET_NO_KERNEL)),true)
PRODUCT_COPY_FILES := \
    $(LOCAL_KERNEL):kernel
endif

PRODUCT_COPY_FILES += \
    device/qss/init.qss.rc:root/init.qss.rc \
    device/qss/init.qss.usb.rc:root/init.qss.usb.rc \
    device/qss/ueventd.qss.rc:root/ueventd.qss.rc \
    device/qss/media_profiles.xml:system/etc/media_profiles.xml \
    device/qss/gps.conf:system/etc/gps.conf \
    device/qss/vold.fstab:system/etc/vold.fstab

# Bluetooth configuration files
PRODUCT_COPY_FILES += \
    system/bluetooth/data/main.le.conf:system/etc/bluetooth/main.conf

# Wifi
ifneq ($(TARGET_PREBUILT_WIFI_MODULE),)
PRODUCT_COPY_FILES += \
    $(TARGET_PREBUILT_WIFI_MODULE):system/lib/modules/bcmdhd.ko
endif
PRODUCT_COPY_FILES += \
    device/qss/bcmdhd.cal:system/etc/wifi/bcmdhd.cal

PRODUCT_PROPERTY_OVERRIDES := \
    wifi.interface=wlan0 \
    wifi.supplicant_scan_interval=15

# Set default USB interface
PRODUCT_DEFAULT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=mass_storage

# Live Wallpapers
PRODUCT_PACKAGES += \
    LiveWallpapers \
    LiveWallpapersPicker \
    VisualizationWallpapers \
    Galaxy4 \
    HoloSpiralWallpaper \
    MagicSmokeWallpapers \
    NoiseField \
    PhaseBeam \
    librs_jni

# Input kl and kcm keymaps
PRODUCT_COPY_FILES += \
    device/qss/qss-keypad.kl:system/usr/keylayout/qss-keypad.kl \
    device/qss/qss-keypad.kcm:system/usr/keychars/qss-keypad.kcm \
    device/qss/cypress-touchkey.kl:system/usr/keylayout/cypress-touchkey.kl \
    device/qss/cypress-touchkey.kcm:system/usr/keychars/cypress-touchkey.kcm \
    device/qss/sec_jack.kl:system/usr/keylayout/sec_jack.kl \
    device/qss/sec_jack.kcm:system/usr/keychars/sec_jack.kcm

# Input device calibration files
PRODUCT_COPY_FILES += \
    device/qss/mxt224_ts.idc:system/usr/idc/mxt224_ts.idc

# These are the hardware-specific features
PRODUCT_COPY_FILES += \
    frameworks/base/data/etc/handheld_core_hardware.xml:system/etc/permissions/handheld_core_hardware.xml \
    frameworks/base/data/etc/android.hardware.camera.flash-autofocus.xml:system/etc/permissions/android.hardware.camera.flash-autofocus.xml \
    frameworks/base/data/etc/android.hardware.location.gps.xml:system/etc/permissions/android.hardware.location.gps.xml \
    frameworks/base/data/etc/android.hardware.wifi.xml:system/etc/permissions/android.hardware.wifi.xml \
    frameworks/base/data/etc/android.hardware.wifi.direct.xml:system/etc/permissions/android.hardware.wifi.direct.xml \
    frameworks/base/data/etc/android.hardware.sensor.proximity.xml:system/etc/permissions/android.hardware.sensor.proximity.xml \
    frameworks/base/data/etc/android.hardware.sensor.light.xml:system/etc/permissions/android.hardware.sensor.light.xml \
    frameworks/base/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:system/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/base/data/etc/android.software.sip.voip.xml:system/etc/permissions/android.software.sip.voip.xml \
    frameworks/base/data/etc/android.hardware.usb.accessory.xml:system/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/base/data/etc/android.hardware.usb.host.xml:system/etc/permissions/android.hardware.usb.host.xml \
    frameworks/base/data/etc/android.hardware.telephony.cdma.xml:system/etc/permissions/android.hardware.telephony.cdma.xml \
    packages/wallpapers/LivePicker/android.software.live_wallpaper.xml:system/etc/permissions/android.software.live_wallpaper.xml

PRODUCT_PROPERTY_OVERRIDES += \
    ro.opengles.version=131072

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=240

PRODUCT_TAGS += dalvik.gc.type-precise

PRODUCT_PACKAGES += \
    librs_jni \
    com.android.future.usb.accessory

# Filesystem management tools
PRODUCT_PACKAGES += \
    make_ext4fs \
    setup_fs

# for bugmailer
ifneq ($(TARGET_BUILD_VARIANT),user)
    PRODUCT_PACKAGES += send_bug
    PRODUCT_COPY_FILES += \
        system/extras/bugmailer/bugmailer.sh:system/bin/bugmailer.sh \
        system/extras/bugmailer/send_bug:system/bin/send_bug
endif

$(call inherit-product, frameworks/base/build/phone-hdpi-512-dalvik-heap.mk)

$(call inherit-product-if-exists, vendor/qss/device-vendor.mk)

#BOARD_WLAN_DEVICE_REV := bcm4329
#WIFI_BAND             := 802_11_ABG
$(call inherit-product-if-exists, hardware/broadcom/wlan/bcmdhd/firmware/bcm4329/device-bcm.mk)
