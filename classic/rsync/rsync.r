/*
 * Memory: about 0.7 MB for the code, 0.2 MB per run, and 320 bytes per
 * file-list entry (files, folders and ._ sidecars alike), plus about
 * 0.3 MB with -z.  6 MB holds about 15,000 entries, 3 MB about 6,000.
 * See docs/CLASSIC_MACOS_PORT.md, "Memory".
 */
#include "Processes.r"
#include "Menus.r"
#include "Dialogs.r"
#include "Finder.r"

#define RSYNCOPE_VERSION_NAME "rsync console"
#include "../version.r"
#define RSYNCOPE_ABOUT_NAME "rsync console"
#include "../about.r"

type 'rSnc' as 'STR ';
resource 'rSnc' (0, purgeable) { "rsync console" };

resource 'FREF' (128, purgeable) {
	'APPL', 0, ""
};

resource 'BNDL' (128, purgeable) {
	'rSnC', 0,
	{
		'ICN#', { 0, 129 };
		'FREF', { 0, 128 };
	}
};

resource 'MENU' (128) {
	128,
	textMenuProc,
	0x7FFFFFFD,
	enabled,
	apple,
	{
		"About rsync console\0xC9", noIcon, noKey, noMark, plain,
		"-", noIcon, noKey, noMark, plain
	}
};

resource 'MENU' (129) {
	129,
	textMenuProc,
	allEnabled,
	enabled,
	"File",
	{
		"Quit", noIcon, "Q", noMark, plain
	}
};

resource 'MBAR' (128) {
	{ 128, 129 }
};

resource 'SIZE' (-1) {
	reserved,
	acceptSuspendResumeEvents,
	reserved,
	canBackground,
	doesActivateOnFGSwitch,
	backgroundAndForeground,
	dontGetFrontClicks,
	ignoreChildDiedEvents,
	is32BitCompatible,
	notHighLevelEventAware,
	onlyLocalHLEvents,
	notStationeryAware,
	dontUseTextEditServices,
	reserved,
	reserved,
	reserved,
	6 * 1024 * 1024,
	3 * 1024 * 1024
};
