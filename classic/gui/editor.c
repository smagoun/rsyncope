/*
 * editor.c: the window that reviews and edits one bookmark.
 *
 * Double-clicking a bookmark opens it here for review; nothing runs until
 * Sync or Preview is clicked.  The modeless dialog uses a DITL resource,
 * so the Dialog Manager handles the text fields, Tab, and the clipboard.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "gui.h"
#include "engine.h"

void	console_set_input(const char *);

enum {
	I_SAVE = 1, I_CANCEL, I_SYNC, I_PREVIEW,
	I_NAME_L, I_NAME, I_PULL, I_PUSH,
	I_HOST_L, I_HOST, I_PORT_L, I_PORT,
	I_MODULE_L, I_MODULE, I_PATH_L, I_PATH,
	I_USER_L, I_USER, I_PASS_L, I_PASS,
	I_LOCAL_L, I_LOCAL, I_CHOOSE,
	I_NETATALK, I_XATTRS, I_DELETE, I_TYPES, I_TEXT, I_EXTS, I_DST,
	I_COMPRESS, I_CHECKSUM, I_EXCL_L, I_EXCL, I_CMD, I_TOCONSOLE
};

static DialogPtr dlg;
static int editing;		/* index into bookmarks, or -1 for new */

/*
 * The password field shows one bullet per character; the characters
 * themselves are kept here, updated as keys and Edit commands change
 * the field (whose text is only bullets).
 */
static char secret[sizeof(((struct bookmark *)0)->pass)];
#define BULLET	'\xa5'		/* MacRoman */

/* Edit text items, in Tab order (Shift-Tab walks this backwards). */
static const short edit_items[] = {
	I_NAME, I_HOST, I_PORT, I_MODULE, I_PATH, I_USER, I_PASS, I_LOCAL,
	I_EXTS, I_EXCL
};
#define NEDIT	(short)(sizeof(edit_items) / sizeof(edit_items[0]))

int
editor_is(WindowPtr w)
{
	return w != NULL && w == (WindowPtr)dlg;
}

int
editor_index(void)
{
	return dlg != NULL ? editing : -2;
}

/* ---- field access --------------------------------------------------------- */

static Handle
item_h(int item)
{
	short type;
	Handle h;
	Rect r;

	GetDialogItem(dlg, item, &type, &h, &r);
	return h;
}

static void
get_text(int item, char *out, size_t sz)
{
	Str255 t;

	GetDialogItemText(item_h(item), t);
	p2c(t, out, sz);
}

static void
set_text(int item, const char *s)
{
	Str255 t;

	c2p(s, t);
	SetDialogItemText(item_h(item), t);
}

static int
get_check(int item)
{
	return GetControlValue((ControlHandle)item_h(item)) != 0;
}

static void
set_check(int item, int on)
{
	SetControlValue((ControlHandle)item_h(item), on ? 1 : 0);
}

static void
read_fields(struct bookmark *b)
{
	char port[16];

	get_text(I_NAME, b->name, sizeof(b->name));
	b->push = get_check(I_PUSH);
	get_text(I_HOST, b->host, sizeof(b->host));
	get_text(I_PORT, port, sizeof(port));
	b->port = atoi(port) > 0 ? atoi(port) : 873;
	get_text(I_MODULE, b->module, sizeof(b->module));
	get_text(I_PATH, b->path, sizeof(b->path));
	get_text(I_USER, b->user, sizeof(b->user));
	snprintf(b->pass, sizeof(b->pass), "%s", secret);
	get_text(I_LOCAL, b->local, sizeof(b->local));
	b->netatalk = get_check(I_NETATALK);
	b->xattrs = get_check(I_XATTRS);
	b->del = get_check(I_DELETE);
	b->mactypes = get_check(I_TYPES);
	b->mactext = get_check(I_TEXT);
	get_text(I_EXTS, b->mactext_exts, sizeof(b->mactext_exts));
	b->dst = get_check(I_DST);
	b->compress = get_check(I_COMPRESS);
	b->checksum = get_check(I_CHECKSUM);
	get_text(I_EXCL, b->exclude, sizeof(b->exclude));
}

static void
write_fields(const struct bookmark *b)
{
	char port[16], bullets[sizeof(secret)];

	set_text(I_NAME, b->name);
	set_check(I_PULL, !b->push);
	set_check(I_PUSH, b->push);
	set_text(I_HOST, b->host);
	snprintf(port, sizeof(port), "%d", b->port);
	set_text(I_PORT, port);
	set_text(I_MODULE, b->module);
	set_text(I_PATH, b->path);
	set_text(I_USER, b->user);
	snprintf(secret, sizeof(secret), "%s", b->pass);
	memset(bullets, BULLET, strlen(secret));
	bullets[strlen(secret)] = '\0';
	set_text(I_PASS, bullets);
	set_text(I_LOCAL, b->local);
	set_check(I_NETATALK, b->netatalk);
	set_check(I_XATTRS, b->xattrs);
	set_check(I_DELETE, b->del);
	set_check(I_TYPES, b->mactypes);
	set_check(I_TEXT, b->mactext);
	set_text(I_EXTS, b->mactext_exts);
	set_check(I_DST, b->dst);
	set_check(I_COMPRESS, b->compress);
	set_check(I_CHECKSUM, b->checksum);
	set_text(I_EXCL, b->exclude);
}

static void
show_command(void)
{
	struct bookmark b;
	char cmd[600];

	bm_defaults(&b);
	read_fields(&b);
	bm_cmdline(&b, 0, cmd, sizeof(cmd));
	if (strlen(cmd) > 250)
		strcpy(cmd + 247, "...");
	set_text(I_CMD, cmd);
}

/* ---- the password field and Shift-Tab ------------------------------------ */

static short
focus_item(void)
{
	return ((DialogPeek)dlg)->editField + 1;
}

/* Replace secret[start, end) with n bytes of text; 0 if it won't fit. */
static int
secret_replace(short start, short end, const char *text, size_t n)
{
	size_t len = strlen(secret);

	if (end > (short)len)
		end = (short)len;
	if (start > end)
		start = end;
	if (len - (size_t)(end - start) + n >= sizeof(secret))
		return 0;
	memmove(secret + start + n, secret + end, len - (size_t)end + 1);
	memcpy(secret + start, text, n);
	return 1;
}

/*
 * A key typed into the password field: record it in secret and turn it
 * into a bullet (or swallow it).  Returns 0 if the event was consumed.
 */
static int
password_key(EventRecord *ev)
{
	TEHandle te = ((DialogPeek)dlg)->textH;
	short start = (*te)->selStart, end = (*te)->selEnd;
	char key = (char)(ev->message & charCodeMask);

	if (key == 0x08) {		/* Backspace */
		if (start == end && start > 0)
			start--;
		secret_replace(start, end, "", 0);
		return 1;
	}
	if ((key >= 0x1C && key <= 0x1F) || key == '\t')  /* arrows, Tab */
		return 1;
	if ((unsigned char)key < 0x20 || key == 0x7F)
		return 0;
	if (!secret_replace(start, end, &key, 1)) {
		SysBeep(1);
		return 0;
	}
	ev->message = (ev->message & ~charCodeMask) | (unsigned char)BULLET;
	return 1;
}

static void
previous_field(void)
{
	short i, cur = focus_item();

	for (i = 0; i < NEDIT; i++)
		if (edit_items[i] == cur)
			break;
	i = (i == 0 || i == NEDIT) ? NEDIT - 1 : i - 1;
	SelectDialogItemText(dlg, edit_items[i], 0, 32767);
}

/* Edit menu: Cut, Copy, Paste, Clear (EDIT_*). */
void
editor_edit(int what)
{
	TEHandle te = ((DialogPeek)dlg)->textH;
	short start, end;
	Handle h;
	long off, len;
	char bullets[sizeof(secret)];

	if (focus_item() != I_PASS) {
		if (what == EDIT_CUT)
			gui_DialogCut(dlg);
		else if (what == EDIT_COPY)
			gui_DialogCopy(dlg);
		else if (what == EDIT_PASTE)
			gui_DialogPaste(dlg);
		else
			gui_DialogDelete(dlg);
		show_command();
		return;
	}
	/* The password is never copied out; it can be pasted in. */
	start = (*te)->selStart;
	end = (*te)->selEnd;
	if (what == EDIT_COPY || what == EDIT_CUT) {
		SysBeep(1);
		return;
	}
	if (what == EDIT_CLEAR) {
		secret_replace(start, end, "", 0);
		TEDelete(te);
		return;
	}
	if ((h = NewHandle(0)) == NULL)
		return;
	len = GetScrap(h, 'TEXT', &off);
	if (len > 0) {
		HLock(h);
		if (secret_replace(start, end, *h, (size_t)len)) {
			memset(bullets, BULLET, (size_t)len);
			TEDelete(te);
			TEInsert(bullets, len, te);
		} else
			SysBeep(1);
		HUnlock(h);
	}
	DisposeHandle(h);
}

/* ---- building the window -------------------------------------------------- */

void
editor_open(int index)
{
	struct bookmark b;
	Str255 t;

	if (dlg != NULL) {
		if (editing == index) {
			SelectWindow((WindowPtr)dlg);
			return;
		}
		editor_close();
	}
	editing = index;
	if (index >= 0)
		b = bookmarks[index];
	else {
		bm_defaults(&b);
		strcpy(b.name, "New bookmark");
	}
	dlg = GetNewDialog(130, NULL, (WindowPtr)-1);
	if (dlg == NULL) {
		app_note("Could not open the bookmark editor.");
		return;
	}
	if (index >= 0) {
		c2p(b.name, t);
		SetWTitle(dlg, t);
	}
	SetPort(dlg);
	write_fields(&b);
	show_command();
	SelectDialogItemText(dlg, I_HOST, 0, 32767);
	ShowWindow(dlg);
}

void
editor_close(void)
{
	if (dlg == NULL)
		return;
	DisposeDialog(dlg);
	dlg = NULL;
	app_update_menus();
}

/* ---- actions ---------------------------------------------------------------- */

/* "Disk:Folder:Sub:" for a folder (vRefNum, dirID). */
static void
folder_path(short vref, long dirid, char *out, size_t sz)
{
	char path[512] = "", part[64], tmp[512];
	CInfoPBRec pb;
	Str63 name;

	for (;;) {
		memset(&pb, 0, sizeof(pb));
		pb.dirInfo.ioNamePtr = name;
		pb.dirInfo.ioVRefNum = vref;
		pb.dirInfo.ioFDirIndex = -1;
		pb.dirInfo.ioDrDirID = dirid;
		if (PBGetCatInfoSync(&pb) != noErr)
			break;
		p2c(name, part, sizeof(part));
		snprintf(tmp, sizeof(tmp), "%s:%s", part, path);
		strcpy(path, tmp);
		if (dirid == 2)		/* fsRtDirID */
			break;
		dirid = pb.dirInfo.ioDrParID;
	}
	snprintf(out, sz, "%s", path);
}

static void
choose_folder(void)
{
	StandardFileReply reply;
	char path[256], prompt[256], name[256];
	Str255 p, n;

	if (gui_string(STR_CHOOSE_PROMPT, prompt, sizeof(prompt)) != 0 ||
	    gui_string(STR_CHOOSE_NAME, name, sizeof(name)) != 0)
		return;
	c2p(prompt, p);
	c2p(name, n);
	StandardPutFile(p, n, &reply);
	if (!reply.sfGood)
		return;
	folder_path(reply.sfFile.vRefNum, reply.sfFile.parID, path,
	    sizeof(path));
	set_text(I_LOCAL, path);
	show_command();
}

/* Validate and store; returns the bookmark's index, or -1. */
static int
save(void)
{
	struct bookmark b;
	char *posix, utf8[600];
	short missing = 0;

	bm_defaults(&b);
	if (editing >= 0)
		b = bookmarks[editing];
	read_fields(&b);
	if (b.name[0] == '\0')
		missing = STR_NEED_NAME;
	else if (b.host[0] == '\0')
		missing = STR_NEED_SERVER;
	else if (b.module[0] == '\0')
		missing = STR_NEED_MODULE;
	else if (b.local[0] == '\0')
		missing = STR_NEED_LOCAL;
	if (missing != 0) {
		gui_note(missing);
		return -1;
	}
	engine_macroman_to_utf8(b.local, utf8, sizeof(utf8));
	if ((posix = engine_hfs_arg(strchr(utf8, ':') ? utf8 : "x")) == NULL) {
		gui_note(STR_BAD_LOCAL);
		return -1;
	}
	free(posix);
	if (editing < 0) {
		if (nbookmarks == BM_MAX) {
			gui_note(STR_TOO_MANY);
			return -1;
		}
		editing = nbookmarks++;
	}
	bookmarks[editing] = b;
	bm_save();
	bookmarks_refresh();
	return editing;
}

void
editor_event(EventRecord *ev)
{
	DialogPtr which;
	short item;
	char key, cmd[600];
	struct bookmark b;
	int idx;

	if ((ev->what == keyDown || ev->what == autoKey) &&
	    !(ev->modifiers & cmdKey)) {
		key = (char)(ev->message & charCodeMask);
		if (key == '\r' || key == 0x03) {
			if (save() >= 0)
				editor_close();
			return;
		}
		if (key == 0x1B) {	/* Escape */
			editor_close();
			return;
		}
		if (key == '\t' && (ev->modifiers & shiftKey)) {
			previous_field();
			return;
		}
		if (focus_item() == I_PASS && !password_key(ev))
			return;
	}
	if (!DialogSelect(ev, &which, &item) || which != dlg)
		return;
	switch (item) {
	case I_SAVE:
		if (save() >= 0)
			editor_close();
		return;
	case I_CANCEL:
		editor_close();
		return;
	case I_SYNC:
	case I_PREVIEW:
		if ((idx = save()) >= 0) {
			app_queue_bookmark(idx, item == I_PREVIEW);
			editor_close();
		}
		return;
	case I_PULL:
	case I_PUSH:
		set_check(I_PULL, item == I_PULL);
		set_check(I_PUSH, item == I_PUSH);
		break;
	case I_NETATALK: case I_XATTRS: case I_DELETE: case I_TYPES:
	case I_TEXT: case I_DST: case I_COMPRESS: case I_CHECKSUM:
		set_check(item, !get_check(item));
		break;
	case I_CHOOSE:
		choose_folder();
		break;
	case I_TOCONSOLE:
		bm_defaults(&b);
		read_fields(&b);
		bm_cmdline(&b, 0, cmd, sizeof(cmd));
		console_set_input(cmd);
		return;
	}
	show_command();
}
