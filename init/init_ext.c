/*
 * Copyright (C) 2011 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>

#include <property_service.h>
#include <init_ext.h>

static char bootmode[10];

static int bootmode_read(void)
{
    int fd, n;
    
    if (bootmode[0])
        return 0;

    fd = open("/sys/class/switch/bootparam/bootmode", O_RDONLY);
    if (fd < 0)
        return fd;

    n = read(fd, bootmode, sizeof(bootmode));
    if (n <= 0) {
        n = -1;
        goto out;
    }

    bootmode[n-1] = '\0';
    n = 0;

out:
    close(fd);
    return n;
}

static void update_property(void)
{
    if (bootmode_read() < 0)
        return;

    if (strcmp("charger", bootmode) == 0)
        property_set("ro.bootmode", bootmode);
    else if (strcmp("recovery", bootmode) == 0)
        property_set("ro.init.rc", "/recovery.qss.rc");
}

void init_ext_initialize(struct init_ext_cb *cb)
{
    cb->update_property = update_property;
}
