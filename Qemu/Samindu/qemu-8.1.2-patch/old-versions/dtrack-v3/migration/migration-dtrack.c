/* Created by Samindu */
#include "qemu/osdep.h"
#include "qemu/cutils.h"

#include "migration/migration-dtrack.h"

#include "qemu/error-report.h"
#include "migration.h"
#include "options.h"
#include "io/channel-null.h"
#include "exec/target_page.h"
#include "exec/ramblock.h"
#include "exec/memory.h"

typedef struct {
	RAMState *rs;
	bool done;
	bool quit;
	bool trigger;
	QemuMutex mutex;
	QemuCond cond;
} DtrackParam;

QemuThread dtrack_thread;
DtrackParam dtrack_param;
QemuCond dtrack_done_cond;
QemuMutex dtrack_done_lock;

static void *do_dirty_tracking(void *arg) {
	DtrackParam *param = arg;

	qemu_mutex_lock(&param->mutex);
	while (!param->quit) {
		if (param->trigger) {
			memory_global_dtrack_dirty_log_sync(false);
			qemu_mutex_unlock(&param->mutex);

			qemu_mutex_lock(&dtrack_done_lock);
			param->done = true;
			qemu_cond_signal(&dtrack_done_cond);
			qemu_mutex_unlock(&dtrack_done_lock);

			qemu_mutex_lock(&param->mutex);
		} else {
			qemu_cond_wait(&param->cond, &param->mutex);
		}
	}
	qemu_mutex_unlock(&param->mutex);
	return NULL;
}

void handle_multi_thread_dirty_track(RAMState *rs) {
	qemu_mutex_lock(&dtrack_done_lock);
retry:
	if (dtrack_param.done) {
		DtrackParam * param = &dtrack_param;
		qemu_mutex_lock(&param->mutex);

		param->done = false;
		param->trigger = true;
		param->rs = rs;

		qemu_cond_signal(&param->cond);
		qemu_mutex_unlock(&param->mutex);
	} else {
		qemu_cond_wait(&dtrack_done_cond, &dtrack_done_lock);
		goto retry;
	}
	// }
	qemu_mutex_unlock(&dtrack_done_lock);
}

void stop_multi_thread_dirty_track(RAMState *rs) {
	qemu_mutex_lock(&dtrack_done_lock);
retry:
	if (dtrack_param.done) {
		DtrackParam * param = &dtrack_param;
		qemu_mutex_lock(&param->mutex);

		param->done = true;
		param->trigger = false;
		param->rs = rs;

		qemu_cond_signal(&param->cond);
		qemu_mutex_unlock(&param->mutex);
	} else {
		qemu_cond_wait(&dtrack_done_cond, &dtrack_done_lock);
		goto retry;
	}
	qemu_mutex_unlock(&dtrack_done_lock);
}

int dirty_track_thread_save_setup(void) {
	qemu_cond_init(&dtrack_done_cond);
	qemu_mutex_init(&dtrack_done_lock);

	dtrack_param.rs = NULL;
	dtrack_param.done = true;
	dtrack_param.trigger = false;
	dtrack_param.quit = false;

	qemu_mutex_init(&dtrack_param.mutex);
	qemu_cond_init(&dtrack_param.cond);

	qemu_thread_create(&dtrack_thread, "dirty_tracking_thread", do_dirty_tracking, &dtrack_param, QEMU_THREAD_JOINABLE);
	return 0;
}

void dirty_track_thread_save_cleanup(void) {
	qemu_mutex_lock(&dtrack_param.mutex);
	dtrack_param.quit = true;
	qemu_cond_signal(&dtrack_param.cond);
	qemu_mutex_unlock(&dtrack_param.mutex);

	qemu_thread_join(&dtrack_thread);
	qemu_mutex_destroy(&dtrack_param.mutex);
	qemu_cond_destroy(&dtrack_param.cond);

	qemu_mutex_destroy(&dtrack_done_lock);
	qemu_cond_destroy(&dtrack_done_cond);
}

/* ------------------ */
