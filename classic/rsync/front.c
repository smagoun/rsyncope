/*
 * front.c: the console front end for rsync on Classic Mac OS.
 *
 * A Retro68 console window with an "rsync>" prompt; commands run through
 * engine.c.
 *
 * Unattended mode (used by classic/emu/boot-test.sh): if a file named
 * "rsync script" is next to the application, each of its lines is run as
 * a command and all output is also written to "rsync log"; if a file
 * named "rsync autoquit" exists too, the Mac shuts down afterwards.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#include "mactoolbox.h"
#include "macposix.h"

#include "../about.h"
#include "engine.h"
#include "../version.h"

#define LINEMAX	2048

enum { M_APPLE = 128, M_FILE };
enum { A_ABOUT = 1, F_QUIT = 1 };

static MenuHandle menus[2];
static int quit_requested;

int	console_ui_init(void);
void	console_ui_event(EventRecord *);
void	console_front_quit(void);

/* ---- console tee to "rsync log" (linked with --wrap=_consolewrite) ---- */

ssize_t	__real__consolewrite(int, const void *, size_t);
static short logref;

ssize_t
__wrap__consolewrite(int fd, const void *buf, size_t len)
{
	char conv[512], crbuf[512];
	const unsigned char *p = buf;
	size_t chunk, n, i;
	long cnt;

	while (len > 0) {
		chunk = len > sizeof(conv) ? sizeof(conv) : len;
		n = engine_utf8_to_macroman(p, chunk, conv);
		if (logref != 0) {
			/* A Mac text file: CR line ends. */
			memcpy(crbuf, conv, n);
			for (i = 0; i < n; i++)
				if (crbuf[i] == '\n')
					crbuf[i] = '\r';
			cnt = (long)n;
			FSWrite(logref, &cnt, crbuf);
			/* Flush so the log survives a crash. */
			FlushVol(NULL, 0);
		}
		__real__consolewrite(fd, conv, n);
		p += chunk;
		len -= chunk;
	}
	return (ssize_t)(p - (const unsigned char *)buf);
}

static void
log_open(void)
{
	FInfo fi;

	FSDelete("\prsync log", 0);
	if (Create("\prsync log", 0, 'ttxt', 'TEXT') != noErr)
		return;
	/*
	 * Unattended runs (the emulator tests) hide the log: System 7.1's
	 * Finder opens each new file in Startup Items, and TeachText would
	 * then take the keyboard.
	 */
	if (access("rsync autoquit", F_OK) == 0 &&
	    GetFInfo("\prsync log", 0, &fi) == noErr) {
		fi.fdFlags |= 0x4000;		/* kIsInvisible */
		SetFInfo("\prsync log", 0, &fi);
	}
	if (FSOpen("\prsync log", 0, &logref) != noErr)
		logref = 0;
}

static void
log_close(void)
{
	if (logref != 0) {
		FSClose(logref);
		logref = 0;
		FlushVol(NULL, 0);
	}
}

/* ---- main ------------------------------------------------------------------ */

static int
read_line(FILE *f, char *buf, size_t len)
{
	size_t n = 0;
	int c;

	while ((c = getc(f)) != EOF && c != '\r' && c != '\n')
		if (n + 1 < len)
			buf[n++] = (char)c;
	buf[n] = '\0';
	return (c == EOF && n == 0) ? -1 : 0;
}

static void
banner(void)
{
	printf("rsync console " RSYNCOPE_VERSION " (openrsync, protocol 29)\n");
	printf("Type a command, e.g.\n");
	printf("  rsync -av --delete server::module/dir \"Macintosh HD:Projects:\"\n");
	printf("HFS paths (Disk:Folder:) are fine.  $(NAME) comes from "
	    "\"rsync prefs\".\n");
	printf("\"rsync --daemon\" serves the modules in \"rsyncd.conf\" (Cmd-. stops).\n");
	printf("Type \"quit\" to leave.\n\n");
}

static int
make_menus(void)
{
	Handle mbar = GetNewMBar(128);

	if (mbar == NULL) {
		fprintf(stderr, "rsync console: could not load menu bar resource 128\n");
		return -1;
	}
	SetMenuBar(mbar);
	menus[0] = GetMenuHandle(M_APPLE);
	menus[1] = GetMenuHandle(M_FILE);
	if (menus[0] == NULL || menus[1] == NULL) {
		fprintf(stderr, "rsync console: could not load menu resources\n");
		return -1;
	}
	AppendResMenu(menus[0], 'DRVR');
	DrawMenuBar();
	return 0;
}

void
console_front_menu(long choice)
{
	short menu = HiWord(choice), item = LoWord(choice);

	if (menu == M_APPLE && item == A_ABOUT) {
		if (about_show() != 0)
			fprintf(stderr, "rsync console: could not open About dialog\n");
	} else if (menu == M_FILE && item == F_QUIT) {
		console_front_quit();
	}
}

void
console_front_quit(void)
{
	quit_requested = 1;
	mp_interrupted = 1;
}

int
console_app_quitting(void)
{
	return quit_requested;
}

int
main(void)
{
	char line[LINEMAX];
	struct stat st;
	FILE *script;
	size_t len;
	int rc;

	if (console_ui_init() != 0 || make_menus() != 0)
		return 1;
	mp_event_hook = console_ui_event;
	engine_grow_stack(256L * 1024);

	if ((script = fopen("rsync script", "r")) != NULL) {
		/* Look now: a command (the daemon) may change directory. */
		int autoquit = stat("rsync autoquit", &st) == 0;

		log_open();
		banner();
		/* Lines may end in CR (Mac) or LF (Unix). */
		while (read_line(script, line, sizeof(line)) != -1) {
			if (line[0] == '\0' || line[0] == '#')
				continue;
			printf("rsync> %s\n", line);
			if (engine_builtin(line))
				continue;
			rc = engine_run_line(line);
			printf("[exit %d]\n", rc);
		}
		fclose(script);
		log_close();
		if (autoquit)
			ShutDwnPower();
		return 0;
	}

	banner();
	while (!quit_requested) {
		printf("rsync> ");
		fflush(stdout);
		if (fgets(line, sizeof(line), stdin) == NULL)
			break;
		len = strlen(line);
		while (len > 0 && (line[len - 1] == '\n' || line[len - 1] == '\r'))
			line[--len] = '\0';
		if (strcmp(line, "quit") == 0 || strcmp(line, "exit") == 0)
			break;
		if (engine_builtin(line))
			continue;
		rc = engine_run_line(line);
		if (rc != 0)
			printf("[exit %d]\n", rc);
	}
	return 0;
}
