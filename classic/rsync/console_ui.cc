#include <retro/ConsoleWindow.h>

#include "mactoolbox.h"

extern "C" {
extern int mp_interrupted;
void console_front_menu(long);
void console_front_quit(void);
int console_app_quitting(void);
void console_ui_event(EventRecord *);
}

namespace {

class MenuConsole : public retro::ConsoleWindow {
public:
	MenuConsole(Rect bounds, ConstStr255Param title)
	    : retro::ConsoleWindow(bounds, title) {}

private:
	char WaitNextChar() override
	{
		EventRecord event;

		for (;;) {
			retro::Console::currentInstance->Idle();
			SystemTask();
			if (!WaitNextEvent(everyEvent, &event, 5, NULL))
				continue;
			console_ui_event(&event);
			if (console_app_quitting())
				return 0;
			if (event.what == keyDown || event.what == autoKey) {
				if (event.modifiers & cmdKey)
					continue;
				return (char)(event.message & charCodeMask);
			}
		}
	}
};

MenuConsole *console;
WindowPtr console_window;

}

extern "C" void
console_ui_event(EventRecord *event)
{
	WindowPtr window;
	short part;
	char key;

	switch (event->what) {
	case mouseDown:
		part = FindWindow(event->where, &window);
		switch (part) {
		case inMenuBar:
			console_front_menu(MenuSelect(event->where));
			HiliteMenu(0);
			break;
		case inSysWindow:
			SystemClick(event, window);
			break;
		case inDrag:
			DragWindow(window, event->where, &qd.screenBits.bounds);
			break;
		case inGoAway:
			if (window == console_window && TrackGoAway(window, event->where))
				console_front_quit();
			break;
		case inGrow: {
			long size = GrowWindow(window, event->where, &qd.screenBits.bounds);

			if (size != 0) {
				short width = (short)(size & 0xFFFF);
				short height = (short)(size >> 16);

				SizeWindow(window, width, height, false);
				if (window == console_window)
					console->Reshape(Rect { 0, 0, height, width });
			}
			break;
		}
		case inContent:
			if (window != FrontWindow())
				SelectWindow(window);
			break;
		}
		break;
	case keyDown:
	case autoKey:
		if (!(event->modifiers & cmdKey))
			break;
		key = (char)(event->message & charCodeMask);
		if (key == '.') {
			mp_interrupted = 1;
		} else if (event->what == keyDown) {
			console_front_menu(MenuKey(key));
			HiliteMenu(0);
		}
		break;
	case updateEvt:
		window = (WindowPtr)event->message;
		if (window == console_window) {
			SetPort(window);
			BeginUpdate(window);
			console->Draw();
			EndUpdate(window);
		}
		break;
	case nullEvent:
		console->Idle();
		break;
	}
}

extern "C" int
console_ui_init(void)
{
	Rect bounds;

	InitGraf(&qd.thePort);
	InitFonts();
	InitWindows();
	InitMenus();
	InitDialogs(NULL);
	InitCursor();
	FlushEvents(everyEvent, 0);

	bounds = qd.screenBits.bounds;
	bounds.top += 40;
	InsetRect(&bounds, 5, 5);
	console = new MenuConsole(bounds, "\prsync console");
	console->setWindowName("rsync console");
	retro::Console::currentInstance = console;
	console_window = FrontWindow();
	return 0;
}
