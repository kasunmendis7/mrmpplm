#!/bin/bash
rsync -av --progress "$(dirname "$0")/qemu-8.1.2-patch/migration/" "$(dirname "$0")/qemu-8.1.2/migration/"
rsync -av --progress "$(dirname "$0")/qemu-8.1.2-patch/include/" "$(dirname "$0")/qemu-8.1.2/include/"
rsync -av --progress "$(dirname "$0")/qemu-8.1.2-patch/qapi/" "$(dirname "$0")/qemu-8.1.2/qapi/"
rsync -av --progress "$(dirname "$0")/qemu-8.1.2-patch/configure" "$(dirname "$0")/qemu-8.1.2/configure"
rsync -av --progress "$(dirname "$0")/qemu-8.1.2-patch/install.sh" "$(dirname "$0")/qemu-8.1.2/install.sh"
rsync -av --progress "$(dirname "$0")/qemu-8.1.2-patch/run.sh" "$(dirname "$0")/qemu-8.1.2/run.sh"
