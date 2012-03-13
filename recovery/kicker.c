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
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/mount.h>
#include "cutils/android_reboot.h"

#include "log.h"

#define MOD_FSR		"/modules/fsr.ko"
#define MOD_FSR_STL	"/modules/fsr_stl.ko"
#define MOD_J4FS	"/modules/j4fs.ko"
#define MOD_PARAM	"/modules/param.ko"

#define PARAM_BLK	"/dev/stl6"
#define PARAM_MNT	"/param"
#define DEBUG_LVL_INF	PARAM_MNT "/debug_level.inf"

extern int init_module(void *, unsigned long, const char *);

/* reads a file, making sure it is terminated with \n \0 */
void *read_file(const char *fn, unsigned *_sz)
{
    char *data;
    int sz;
    int fd;

    data = 0;
    fd = open(fn, O_RDONLY);
    if(fd < 0) return 0;

    sz = lseek(fd, 0, SEEK_END);
    if(sz < 0) goto oops;

    if(lseek(fd, 0, SEEK_SET) != 0) goto oops;

    data = (char*) malloc(sz + 2);
    if(data == 0) goto oops;

    if(read(fd, data, sz) != sz) goto oops;
    close(fd);
    data[sz] = '\n';
    data[sz+1] = 0;
    if(_sz) *_sz = sz;
    return data;

oops:
    close(fd);
    if(data != 0) free(data);
    return 0;
}

static int write_file(const char *path, const char *value)
{
    int fd, ret, len;

    fd = open(path, O_WRONLY|O_CREAT, 0622);

    if (fd < 0)
        return -errno;

    len = strlen(value);

    do {
        ret = write(fd, value, len);
    } while (ret < 0 && errno == EINTR);

    close(fd);
    if (ret < 0) {
        return -errno;
    } else {
        return 0;
    }
}

static int _insmod(const char *filename, char *options)
{
	void *module;
	unsigned size;
	int ret;

	module = read_file(filename, &size);
	if (!module)
		return -1;

	ret = init_module(module, size, options);

	free(module);

	return ret;
}

static int insmod(const char *filename, char *options)
{
	int ret = _insmod(filename, options);
	if (ret)
		ERROR("insmod error: %s options=%s err=%d", filename, options, ret);
	return ret;
}

int main(int argc, char **argv)
{
	int ret = 0;

	klog_init();
	klog_set_level(7);

	INFO("mount: /dev");
	ret = mount("devtmpfs", "/dev", "devtmpfs", 0, NULL);
	if (ret) {
		ERROR("mount error: %s => %s err=%d", "devtmpfs", "/dev", ret);
		goto err;
	}

	INFO("insmod: fsr");
	ret = insmod(MOD_FSR, "");
	if (ret)
		goto err;

	INFO("insmod: fsr_stl");
	ret = insmod(MOD_FSR_STL, "");
	if (ret)
		goto err;

	INFO("insmod: j4fs");
	ret = insmod(MOD_J4FS, "");
	if (ret)
		goto err;

	INFO("mount: /param");
	ret = mount(PARAM_BLK, PARAM_MNT, "j4fs", 0, NULL);
	if (ret) {
		ERROR("mount error: %s => %s err=%d", PARAM_BLK, PARAM_MNT, ret);
		goto err;
	}

	INFO("insmod: param");
	ret = insmod(MOD_PARAM, "");
	if (ret)
		goto err;

	INFO("set: " DEBUG_LVL_INF " => DLOW");
	ret = write_file(DEBUG_LVL_INF, "DLOW");
	if (ret)
		goto err;

	INFO("rebooting...");
	android_reboot(ANDROID_RB_RESTART, 0, 0);

	while(1)
		sleep(1000);
err:
	return -ret;
};
