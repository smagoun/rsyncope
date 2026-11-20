#include "version.h"

resource 'vers' (1, purgeable) {
	RSYNCOPE_VERSION_MAJOR, RSYNCOPE_VERSION_MINOR_BUGFIX, 0x80, 0, 0,
	RSYNCOPE_VERSION, RSYNCOPE_VERSION ", Copyright (c) 2026 The rsyncope contributors"
};

resource 'vers' (2, purgeable) {
	RSYNCOPE_VERSION_MAJOR, RSYNCOPE_VERSION_MINOR_BUGFIX, 0x80, 0, 0,
	RSYNCOPE_VERSION, RSYNCOPE_VERSION_NAME " " RSYNCOPE_VERSION
};
