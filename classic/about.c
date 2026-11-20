#include "mactoolbox.h"

#include "about.h"

static TEHandle about_license;
static ControlHandle about_scroll;

enum {
	ABOUT_OK = 1, ABOUT_TITLE, ABOUT_DESC, ABOUT_LICENSING,
	ABOUT_TEXT, ABOUT_SCROLL
};

static short
about_line_height(void)
{
	return (*about_license)->lineHeight > 0 ?
	    (*about_license)->lineHeight : 12;
}

static int
about_top_line(void)
{
	return ((*about_license)->viewRect.top -
	    (*about_license)->destRect.top) / about_line_height();
}

static void
about_scroll_to(int line)
{
	int max = GetControlMaximum(about_scroll);

	if (line < 0)
		line = 0;
	if (line > max)
		line = max;
	TEScroll(0, (short)((about_top_line() - line) * about_line_height()),
	    about_license);
	SetControlValue(about_scroll, (short)line);
}

static pascal void
about_scroll_action(ControlHandle control, short part)
{
	int page = ((*about_license)->viewRect.bottom -
	    (*about_license)->viewRect.top) / about_line_height() - 1;
	int line = GetControlValue(control);

	if (page < 1)
		page = 1;
	switch (part) {
	case inUpButton:
		line--;
		break;
	case inDownButton:
		line++;
		break;
	case inPageUp:
		line -= page;
		break;
	case inPageDown:
		line += page;
		break;
	}
	about_scroll_to(line);
}

static void
about_draw(DialogPtr d)
{
	Rect r = (*about_license)->viewRect;

	InsetRect(&r, -2, -2);
	FrameRect(&r);
	TEUpdate(&d->portRect, about_license);
	DrawControls(d);
}

static pascal Boolean
about_filter(DialogPtr d, EventRecord *ev, short *item)
{
	ControlHandle control;
	Point p;
	short part;
	char key;

	SetPort(d);
	if (ev->what == updateEvt) {
		BeginUpdate(d);
		EraseRect(&d->portRect);
		DrawDialog(d);
		about_draw(d);
		EndUpdate(d);
		return true;
	}
	if (ev->what == mouseDown) {
		p = ev->where;
		GlobalToLocal(&p);
		if ((part = FindControl(p, d, &control)) != 0 &&
		    control == about_scroll) {
			if (part == inThumb) {
				TrackControl(control, p, NULL);
				about_scroll_to(GetControlValue(control));
			} else
				TrackControl(control, p,
				    (ControlActionUPP)about_scroll_action);
			return true;
		}
		if (PtInRect(p, &(*about_license)->viewRect)) {
			TEClick(p, (ev->modifiers & shiftKey) != 0,
			    about_license);
			return true;
		}
		return false;
	}
	if (ev->what != keyDown && ev->what != autoKey)
		return false;
	key = (char)(ev->message & charCodeMask);
	if (key == '\r' || key == 0x03) {
		*item = ABOUT_OK;
		return true;
	}
	if (ev->modifiers & cmdKey) {
		if (key == 'c' || key == 'C') {
			TECopy(about_license);
			return true;
		}
		return false;
	}
	switch (key) {
	case 0x1E:			/* Up arrow */
		about_scroll_to(GetControlValue(about_scroll) - 1);
		return true;
	case 0x1F:			/* Down arrow */
		about_scroll_to(GetControlValue(about_scroll) + 1);
		return true;
	}
	return false;
}

static int
about_set_string(DialogPtr d, short item, short id)
{
	Handle text = GetResource('STR ', id), item_handle;
	short type;
	Rect r;

	if (text == NULL)
		return -1;
	GetDialogItem(d, item, &type, &item_handle, &r);
	HLock(text);
	if (item == ABOUT_OK)
		SetControlTitle((ControlHandle)item_handle, (StringPtr)*text);
	else
		SetDialogItemText(item_handle, (StringPtr)*text);
	HUnlock(text);
	ReleaseResource(text);
	return 0;
}

static pascal void
about_placeholder(DialogPtr d, short item)
{
	/* The user items supply bounds; about_draw paints their contents. */
	(void)d;
	(void)item;
}

static void
about_item_rect(DialogPtr d, short item, Rect *r)
{
	Handle h;
	short type;

	GetDialogItem(d, item, &type, &h, r);
	SetDialogItem(d, item, type, (Handle)about_placeholder, r);
}

int
about_show(void)
{
	Handle license = NULL;
	DialogPtr d = GetNewDialog(128, NULL, (WindowPtr)-1);
	short hit = 0;
	Rect r;
	long len;

	if (d == NULL)
		goto fail;
	if (about_set_string(d, ABOUT_OK, 131) != 0 ||
	    about_set_string(d, ABOUT_TITLE, 128) != 0 ||
	    about_set_string(d, ABOUT_DESC, 129) != 0 ||
	    about_set_string(d, ABOUT_LICENSING, 130) != 0)
		goto fail;
	license = GetResource('TEXT', 128);
	if (license == NULL)
		goto fail;

	MoveWindow(d, (qd.screenBits.bounds.right -
	    (d->portRect.right - d->portRect.left)) / 2,
	    qd.screenBits.bounds.top + 24, false);
	SetPort(d);
	about_item_rect(d, ABOUT_TEXT, &r);
	about_license = TENew(&r, &r);
	if (about_license == NULL)
		goto fail;
	about_item_rect(d, ABOUT_SCROLL, &r);
	about_scroll = NewControl(d, &r, "\p", true, 0, 0, 0,
	    scrollBarProc, 0);
	if (about_scroll == NULL)
		goto fail;
	len = GetHandleSize(license);
	HLock(license);
	TESetText(*license, len, about_license);
	HUnlock(license);
	ReleaseResource(license);
	license = NULL;
	TECalText(about_license);
	SetControlMaximum(about_scroll, (short)
	    (((*about_license)->nLines >
	    ((*about_license)->viewRect.bottom -
	    (*about_license)->viewRect.top) / about_line_height()) ?
	    (*about_license)->nLines -
	    ((*about_license)->viewRect.bottom -
	    (*about_license)->viewRect.top) / about_line_height() : 0));
	TEActivate(about_license);
	SetDialogDefaultItem(d, ABOUT_OK);
	ShowWindow(d);
	about_draw(d);
	while (hit != ABOUT_OK)
		ModalDialog((ModalFilterUPP)about_filter, &hit);
	TEDispose(about_license);
	DisposeControl(about_scroll);
	about_license = NULL;
	about_scroll = NULL;
	DisposeDialog(d);
	return 0;

fail:
	if (license != NULL)
		ReleaseResource(license);
	if (about_license != NULL)
		TEDispose(about_license);
	if (about_scroll != NULL)
		DisposeControl(about_scroll);
	about_license = NULL;
	about_scroll = NULL;
	if (d != NULL)
		DisposeDialog(d);
	return -1;
}
