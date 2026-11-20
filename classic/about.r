type 'TEXT' {
	string;
};

resource 'STR ' (128) {
	RSYNCOPE_ABOUT_NAME " " RSYNCOPE_VERSION
};

resource 'STR ' (129) {
	"A Classic Mac OS GUI and port derived from Apple's fork of openrsync."
};

resource 'STR ' (130) {
	"The Mac OS implementation is licensed under the MIT License. "
	"Portions of the software (the openrsync core) are licensed under "
	"the ISC License."
};

resource 'STR ' (131) {
	"OK"
};

resource 'DLOG' (128) {
	{ 0, 0, 260, 470 },
	dBoxProc,
	invisible,
	noGoAway,
	0,
	128,
	"About " RSYNCOPE_ABOUT_NAME,
	noAutoCenter
};

resource 'DITL' (128) {
	{
		{ 228, 384, 248, 456 }, Button { enabled, "" };
		{ 12, 14, 28, 456 }, StaticText { disabled, "" };
		{ 32, 14, 64, 456 }, StaticText { disabled, "" };
		{ 68, 14, 116, 456 }, StaticText { disabled, "" };
		{ 120, 16, 218, 438 }, UserItem { disabled };
		{ 118, 439, 220, 455 }, UserItem { disabled };
	}
};

resource 'TEXT' (128) {
	"MIT License\r\r"
	"Copyright (c) 2026 The rsyncope contributors\r\r"
	"Permission is hereby granted, free of charge, to any person "
	"obtaining a copy of this software and associated documentation "
	"files (the \"Software\"), to deal in the Software without "
	"restriction, including without limitation the rights to use, "
	"copy, modify, merge, publish, distribute, sublicense, and/or sell "
	"copies of the Software, and to permit persons to whom the Software "
	"is furnished to do so, subject to the following conditions:\r\r"
	"The above copyright notice and this permission notice shall be "
	"included in all copies or substantial portions of the Software.\r\r"
	"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, "
	"EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF "
	"MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND "
	"NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT "
	"HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, "
	"WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING "
	"FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR "
	"OTHER DEALINGS IN THE SOFTWARE.\r\r"
	"------------------------------------------------------------\r\r"
	"openrsync core \0xD1 ISC License\r\r"
	"Copyright (c) 2019, Kristaps Dzonsons <kristaps@bsd.lv>\r\r"
	"Permission to use, copy, modify, and/or distribute this software "
	"for any purpose with or without fee is hereby granted, provided "
	"that the above copyright notice and this permission notice appear "
	"in all copies.\r\r"
	"THE SOFTWARE IS PROVIDED \"AS IS\" AND THE AUTHOR DISCLAIMS ALL "
	"WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED "
	"WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE "
	"AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR "
	"CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM "
	"LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, "
	"NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN "
	"CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE."
};
