/* Created by Samindu */
#ifndef MIGRATION_DTRACK_H
#define MIGRATION_DTRACK_H

#include "qemu-file.h"
#include "ram.h"

extern QemuCond dtrack_done_cond;
extern QemuMutex dtrack_done_lock;

int dirty_track_thread_save_setup(void);
void dirty_track_thread_save_cleanup(void);

void handle_multi_thread_dirty_track(void);
void stop_multi_thread_dirty_track(RAMState *rs);

#endif
/* -------------------- */
