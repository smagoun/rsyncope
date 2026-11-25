#include "Processes.r"
#include "Menus.r"
#include "Dialogs.r"
#include "Finder.r"

#define RSYNCOPE_VERSION_NAME "rsyncope"
#include "../version.r"
#define RSYNCOPE_ABOUT_NAME "rsyncope"
#include "../about.r"

/* Resource type definitions */
/* Retro68's Multiversal Rez headers do not define CNTL. */
#ifndef __CONTROLS_R__
type 'CNTL' {
	rect;
	integer;
	byte;
	fill byte;
	integer;
	integer;
	integer;
	longint;
	pstring;
};
#endif

type 'rSnc' as 'STR ';
resource 'rSnc' (0, purgeable) { "rsyncope" };

resource 'FREF' (128, purgeable) {
	'APPL', 0, ""
};

resource 'FREF' (129, purgeable) {
	'rsBk', 1, ""
};

resource 'BNDL' (128, purgeable) {
	'rSnc', 0,
	{
		'ICN#', { 0, 128, 1, 130 };
		'FREF', { 0, 128, 1, 129 };
	}
};

data 'ICN#' (128) {
	$"0000 0000 0003 F800 0004 0400 000C 07FE"
	$"0010 0001 0010 0001 0010 3FE1 0010 1021"
	$"0010 0821 0010 1021 0010 2021 0010 6821"
	$"0010 A0A1 1F91 5561 2052 B221 4077 DC01"
	$"800E DBFE 801F B000 803E E000 8477 C800"
	$"86FF 8800 87FF 0800 87FE 0800 87FC 0800"
	$"87F8 0800 87F0 0800 87F0 0800 87F8 0800"
	$"8000 0800 8000 0800 7FFF F000 0000 0000"
	$"0000 0000 0003 F800 0007 FC00 000F FFFE"
	$"001F FFFF 001F FFFF 001F FFFF 001F FFFF"
	$"001F FFFF 001F FFFF 001F FFFF 001F FFFF"
	$"001F FFFF 1F9F FFFF 3FDF FFFF 7FFF FFFF"
	$"FFFF FBFE FFFF F000 FFFF F800 FFFF F800"
	$"FFFF F800 FFFF F800 FFFF F800 FFFF F800"
	$"FFFF F800 FFFF F800 FFFF F800 FFFF F800"
	$"FFFF F800 FFFF F800 7FFF F000 0000 0000"
};

data 'ics#' (128) {
	$"01E0 023F 0401 047D 0425 0445 7C8D CF95"
	$"83E1 A7BE BF20 BC20 BC20 BE20 8020 FFC0"
	$"01E0 03FF 07FF 07FF 07FF 07FF 7FFF FFFF"
	$"FFFF FFFE FFE0 FFE0 FFE0 FFE0 FFE0 FFC0"
};

data 'icl8' (128) {
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 FFFF"
	$"FFFF FFFF FF00 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 00FF 5454"
	$"5454 5454 54FF 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 FFFF 5454"
	$"5454 5454 54FF FFFF FFFF FFFF FFFF FF00"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 5454 5454 5454 5454 5454 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 5454 5454 5454 5454 5454 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 FFFF FFFF FFFF FFFF FF54 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 54FF ECEC ECEC ECEC FF54 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 5454 FFEC ECEC ECEC FF54 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 54FF ECEC ECEC ECEC FF54 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"5454 FFEC ECEC ECEC ECEC FF54 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"54FF D8EC D8EC ECEC ECEC FF54 5454 54FF"
	$"0000 0000 0000 0000 0000 00FF 5454 5454"
	$"FFEC D8EC ECEC ECEC FFEC FF54 5454 54FF"
	$"0000 00FF FFFF FFFF FF00 00FF 5454 54FF"
	$"ECD8 ECD8 ECD8 ECFF 54FF FF54 5454 54FF"
	$"0000 FF33 3333 3333 33FF 00FF 5454 FFEC"
	$"D8EC D8D8 ECEC FF54 5454 FF54 5454 54FF"
	$"00FF 3333 3333 3333 33FF FFFF 54FF D8D8"
	$"D8D8 ECD8 D8FF 5454 5454 5454 5454 54FF"
	$"FF33 3333 3333 3333 3333 3333 FFD8 D8EC"
	$"D8D8 ECD8 FF00 FFFF FFFF FFFF FFFF FF00"
	$"FF33 3333 3333 3333 3333 33FF D8D8 D8D8"
	$"D8EC FFFF 0000 0000 0000 0000 0000 0000"
	$"FF33 3333 3333 3333 3333 FFD8 D8D8 D8EC"
	$"D8D8 FF33 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF 3333 33FF D8D8 ECD8 D8D8"
	$"D8FF 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF FF33 FFD8 D8D8 D8D8 D8D8"
	$"FF33 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF D8FF D8D8 D8D8 D8D8 D8FF"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF D8D8 D8D8 D8D8 D8FF FF33"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF D8D8 D8D8 D8D8 D8FF 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF D8D8 D8D8 D8D8 FF33 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF D8D8 D8D8 D8FF 3333 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF D8D8 D8D8 D8FF 3333 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 33FF FFFF FFFF FFFF FF33 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 3333 3333 3333 3333 3333 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"FF33 3333 3333 3333 3333 3333 3333 3333"
	$"3333 3333 FF00 0000 0000 0000 0000 0000"
	$"00FF FFFF FFFF FFFF FFFF FFFF FFFF FFFF"
	$"FFFF FFFF 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000"
};

data 'ics8' (128) {
	$"0000 0000 0000 00FF FFFF FF00 0000 0000"
	$"0000 0000 0000 FF54 5454 FFFF FFFF FFFF"
	$"0000 0000 00FF 5454 5454 5454 5454 54FF"
	$"0000 0000 00FF 5454 54FF FFFF FFFF 54FF"
	$"0000 0000 00FF 5454 5454 FFEC ECFF 54FF"
	$"0000 0000 00FF 5454 54FF ECEC ECFF 54FF"
	$"00FF FFFF FFFF 5454 FFEC ECEC FFFF 54FF"
	$"FFFF 3333 FFFF FFFF FFEC ECFF 54FF 54FF"
	$"FF33 3333 3333 D8D8 D8FF FF54 5454 54FF"
	$"FF33 FF33 33D8 D8D8 D833 FFFF FFFF FF00"
	$"FF33 FFD8 D8D8 D8D8 3333 FF00 0000 0000"
	$"FF33 FFD8 D8D8 3333 3333 FF00 0000 0000"
	$"FF33 FFD8 D8D8 3333 3333 FF00 0000 0000"
	$"FF33 FFFF FFFF FF33 3333 FF00 0000 0000"
	$"FF33 3333 3333 3333 3333 FF00 0000 0000"
	$"FFFF FFFF FFFF FFFF FFFF 0000 0000 0000"
};

data 'icl4' (128) {
	$"0000 0000 0000 0000 0000 0000 0000 0000"
	$"0000 0000 0000 00FF FFFF F000 0000 0000"
	$"0000 0000 0000 0FCC CCCC CF00 0000 0000"
	$"0000 0000 0000 FFCC CCCC CFFF FFFF FFF0"
	$"0000 0000 000F CCCC CCCC CCCC CCCC CCCF"
	$"0000 0000 000F CCCC CCCC CCCC CCCC CCCF"
	$"0000 0000 000F CCCC CCFF FFFF FFFC CCCF"
	$"0000 0000 000F CCCC CCCF 6666 66FC CCCF"
	$"0000 0000 000F CCCC CCCC F666 66FC CCCF"
	$"0000 0000 000F CCCC CCCF 6666 66FC CCCF"
	$"0000 0000 000F CCCC CCF6 6666 66FC CCCF"
	$"0000 0000 000F CCCC CF36 3666 66FC CCCF"
	$"0000 0000 000F CCCC F636 6666 F6FC CCCF"
	$"000F FFFF F00F CCCF 6363 636F CFFC CCCF"
	$"00FB BBBB BF0F CCF6 3633 66FC CCFC CCCF"
	$"0FBB BBBB BFFF CF33 3363 3FCC CCCC CCCF"
	$"FBBB BBBB BBBB F336 3363 F0FF FFFF FFF0"
	$"FBBB BBBB BBBF 3333 36FF 0000 0000 0000"
	$"FBBB BBBB BBF3 3336 33FB F000 0000 0000"
	$"FBBB BFBB BF33 6333 3FBB F000 0000 0000"
	$"FBBB BFFB F333 3333 FBBB F000 0000 0000"
	$"FBBB BF3F 3333 333F BBBB F000 0000 0000"
	$"FBBB BF33 3333 3FFB BBBB F000 0000 0000"
	$"FBBB BF33 3333 3FBB BBBB F000 0000 0000"
	$"FBBB BF33 3333 FBBB BBBB F000 0000 0000"
	$"FBBB BF33 333F BBBB BBBB F000 0000 0000"
	$"FBBB BF33 333F BBBB BBBB F000 0000 0000"
	$"FBBB BFFF FFFF FBBB BBBB F000 0000 0000"
	$"FBBB BBBB BBBB BBBB BBBB F000 0000 0000"
	$"FBBB BBBB BBBB BBBB BBBB F000 0000 0000"
	$"0FFF FFFF FFFF FFFF FFFF 0000 0000 0000"
	$"0000 0000 0000 0000 0000 0000 0000 0000"
};

data 'ics4' (128) {
	$"0000 000F FFF0 0000 0000 00FC CCFF FFFF"
	$"0000 0FCC CCCC CCCF 0000 0FCC CFFF FFCF"
	$"0000 0FCC CCF6 6FCF 0000 0FCC CF66 6FCF"
	$"0FFF FFCC F666 FFCF FFBB FFFF F66F CFCF"
	$"FBBB BB33 3FFC CCCF FBFB B333 3BFF FFF0"
	$"FBF3 3333 BBF0 0000 FBF3 33BB BBF0 0000"
	$"FBF3 33BB BBF0 0000 FBFF FFFB BBF0 0000"
	$"FBBB BBBB BBF0 0000 FFFF FFFF FF00 0000"
};


resource 'STR ' (132) { "Start Server" };
resource 'STR ' (133) { "Stop Server" };
resource 'STR ' (134) { "Server off" };
resource 'STR ' (135) { "Server on: rsync://" };
resource 'STR ' (136) { "Delete this bookmark?" };
resource 'STR ' (137) { "Delete" };
resource 'STR ' (138) { "Cancel" };
resource 'STR ' (139) { "Please fill in a name." };
resource 'STR ' (140) { "Please fill in the server." };
resource 'STR ' (141) { "Please fill in the module." };
resource 'STR ' (142) { "Please fill in the local folder." };
resource 'STR ' (143) {
	"The local folder must be a full path such as "
	"\"Macintosh HD:Projects:MyApp:\" (use Choose...)."
};
resource 'STR ' (144) { "There are too many bookmarks." };
resource 'STR ' (145) { "Open the folder to sync, then click Save:" };
resource 'STR ' (146) { "(this folder)" };
resource 'STR ' (147) { "Could not save the bookmarks file \"rsync Bookmarks\"." };
resource 'STR ' (148) { "Could not set Finder info for the bookmarks file." };
/* Generic confirmation or notification dialog. */
resource 'DLOG' (129) {
	{ 0, 0, 130, 340 },
	dBoxProc,
	invisible,
	noGoAway,
	0,
	129,
	"",
	noAutoCenter
};

resource 'DITL' (129) {
	{
		{ 98, 254, 118, 326 }, Button { enabled, "" };
		{ 98, 168, 118, 240 }, Button { enabled, "" };
		{ 12, 14, 90, 326 }, StaticText { disabled, "" };
	}
};

/* Bookmark editor. Item order matches editor.c. */
resource 'DLOG' (130) {
	{ 44, 60, 466, 540 },
	noGrowDocProc,
	invisible,
	goAway,
	2,
	130,
	"New Bookmark",
	noAutoCenter
};

resource 'DITL' (130) {
	{
		{ 390, 396, 410, 466 }, Button { enabled, "Save" };
		{ 390, 316, 410, 386 }, Button { enabled, "Cancel" };
		{ 390, 96, 410, 166 }, Button { enabled, "Sync" };
		{ 390, 14, 410, 86 }, Button { enabled, "Preview" };
		{ 12, 14, 28, 104 }, StaticText { disabled, "Name:" };
		{ 12, 110, 28, 466 }, EditText { enabled, "" };
		{ 38, 110, 56, 260 }, RadioButton { enabled, "Pull from server" };
		{ 38, 270, 56, 420 }, RadioButton { enabled, "Push to server" };
		{ 64, 14, 80, 104 }, StaticText { disabled, "Server:" };
		{ 64, 110, 80, 340 }, EditText { enabled, "" };
		{ 64, 352, 80, 394 }, StaticText { disabled, "Port:" };
		{ 64, 400, 80, 466 }, EditText { enabled, "" };
		{ 90, 14, 106, 104 }, StaticText { disabled, "Module:" };
		{ 90, 110, 106, 220 }, EditText { enabled, "" };
		{ 90, 232, 106, 274 }, StaticText { disabled, "Path:" };
		{ 90, 280, 106, 466 }, EditText { enabled, "" };
		{ 116, 14, 132, 104 }, StaticText { disabled, "User:" };
		{ 116, 110, 132, 220 }, EditText { enabled, "" };
		{ 116, 232, 132, 304 }, StaticText { disabled, "Password:" };
		{ 116, 310, 132, 466 }, EditText { enabled, "" };
		{ 142, 14, 158, 104 }, StaticText { disabled, "Local folder:" };
		{ 142, 110, 158, 380 }, EditText { enabled, "" };
		{ 140, 390, 160, 466 }, Button { enabled, "Choose\0xC9" };
		{ 174, 14, 192, 466 }, CheckBox { enabled,
		    "Resource forks and Finder info (netatalk ._ files)" };
		{ 194, 14, 212, 466 }, CheckBox { enabled,
		    "Server is a Mac running OS X (Apple -E)" };
		{ 214, 14, 232, 466 }, CheckBox { enabled,
		    "Delete files that are not in the source" };
		{ 234, 14, 252, 466 }, CheckBox { enabled,
		    "Set type and creator by name (--mac-types)" };
		{ 254, 14, 272, 220 }, CheckBox { enabled, "Mac line endings for:" };
		{ 255, 226, 271, 466 }, EditText { enabled, "" };
		{ 274, 14, 292, 466 }, CheckBox { enabled,
		    "Ignore 1-hour (daylight saving) differences" };
		{ 294, 14, 312, 150 }, CheckBox { enabled, "Compress" };
		{ 294, 160, 312, 466 }, CheckBox { enabled, "Compare contents (slow)" };
		{ 320, 14, 336, 104 }, StaticText { disabled, "Exclude:" };
		{ 320, 110, 336, 466 }, EditText { enabled, "" };
		{ 346, 14, 378, 380 }, StaticText { disabled, "" };
		{ 350, 390, 370, 466 }, Button { enabled, "To Console" };
	}
};

resource 'WIND' (128) {
	{ 42, 10, 240, 530 }, documentProc, visible, goAway, 0,
	"rsync Bookmarks", noAutoCenter
};

resource 'WIND' (129) {
	{ 270, 10, 470, 630 }, documentProc, visible, goAway, 1,
	"rsync Console", noAutoCenter
};

/* Bookmark buttons and the console scroll bar. Layout is adjusted on resize. */
resource 'CNTL' (128) { { 0, 0, 20, 66 }, 0, 1, 1, 0, 0, 0, "New\0xC9" };
resource 'CNTL' (129) { { 0, 0, 20, 66 }, 0, 1, 1, 0, 0, 1, "Edit\0xC9" };
resource 'CNTL' (130) { { 0, 0, 20, 66 }, 0, 1, 1, 0, 0, 2, "Delete" };
resource 'CNTL' (131) { { 0, 0, 20, 72 }, 0, 1, 1, 0, 0, 3, "Preview" };
resource 'CNTL' (132) { { 0, 0, 20, 72 }, 0, 1, 1, 0, 0, 4, "Sync" };
resource 'CNTL' (133) { { 0, 0, 20, 96 }, 0, 1, 1, 0, 0, 5, "Stop Server" };
resource 'CNTL' (134) { { 0, 0, 100, 16 }, 0, 1, 0, 0, 16, 0, "" };

/* Memory for rsync: the file list and buffers need a few megabytes. */
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

/* Menu resources: enable flags disable separator item numbers. */
resource 'MENU' (128) {
	128,
	textMenuProc,
	0x7FFFFFFD,
	enabled,
	apple,
	{
		"About rsyncope\0xC9", noIcon, noKey, noMark, plain,
		"-", noIcon, noKey, noMark, plain
	}
};

resource 'MENU' (129) {
	129,
	textMenuProc,
	0x7FFFFFEB,
	enabled,
	"File",
	{
		"New Bookmark", noIcon, "N", noMark, plain,
		"Open Bookmark", noIcon, "O", noMark, plain,
		"-", noIcon, noKey, noMark, plain,
		"Close", noIcon, "W", noMark, plain,
		"-", noIcon, noKey, noMark, plain,
		"Quit", noIcon, "Q", noMark, plain
	}
};

resource 'MENU' (130) {
	130,
	textMenuProc,
	0x7FFFFFFD,
	enabled,
	"Edit",
	{
		"Undo", noIcon, "Z", noMark, plain,
		"-", noIcon, noKey, noMark, plain,
		"Cut", noIcon, "X", noMark, plain,
		"Copy", noIcon, "C", noMark, plain,
		"Paste", noIcon, "V", noMark, plain,
		"Clear", noIcon, noKey, noMark, plain,
		"Select All", noIcon, "A", noMark, plain
	}
};

resource 'MENU' (131) {
	131,
	textMenuProc,
	0x7FFFFFF7,
	enabled,
	"Sync",
	{
		"Sync Now", noIcon, "R", noMark, plain,
		"Preview", noIcon, "P", noMark, plain,
		"Stop", noIcon, ".", noMark, plain,
		"-", noIcon, noKey, noMark, plain,
		"Copy Command to Console", noIcon, noKey, noMark, plain
	}
};

resource 'MENU' (132) {
	132,
	textMenuProc,
	allEnabled,
	enabled,
	"Server",
	{
		"Start Server", noIcon, noKey, noMark, plain,
		"Start Server at Launch", noIcon, noKey, noMark, plain
	}
};

resource 'MENU' (133) {
	133,
	textMenuProc,
	allEnabled,
	enabled,
	"Window",
	{
		"Bookmarks", noIcon, "1", noMark, plain,
		"Console", noIcon, "2", noMark, plain
	}
};

/* Menu bar resource */
resource 'MBAR' (128) {
	{ 128, 129, 130, 131, 132, 133 }
};
