/* The terminal, Windows side. Same five functions as src/posix.
 *
 * Reference terminal: Windows Terminal. The console is switched to
 * virtual-terminal mode in both directions, so the bytes that go in
 * and out are the same escape sequences as on POSIX and nothing above
 * this file knows which system it runs on.
 *
 * NOT YET RUN ON A REAL CONSOLE: written from the Win32 documentation
 * and checked by compilation only. Treat every line as unverified.
 */

#include <windows.h>

/* Alternate screen on, cursor hidden / colours reset, cursor shown,
 * alternate screen off. */
static const char enter[] = "\x1b[?1049h\x1b[?25l";
static const char leave[] = "\x1b[0m\x1b[?25h\x1b[?1049l";

static HANDLE input, output;
static DWORD saved_input_mode, saved_output_mode;
static UINT saved_output_cp;
static int is_open = 0;
static int exit_hook_installed = 0;

void thuja_term_close(void)
{
    if (is_open) {
        DWORD ignored;

        WriteFile(output, leave, sizeof leave - 1, &ignored, NULL);
        SetConsoleMode(input, saved_input_mode);
        SetConsoleMode(output, saved_output_mode);
        SetConsoleOutputCP(saved_output_cp);
        is_open = 0;
    }
}

int thuja_term_open(void)
{
    if (is_open)
        return 0;

    input = GetStdHandle(STD_INPUT_HANDLE);
    output = GetStdHandle(STD_OUTPUT_HANDLE);
    if (!GetConsoleMode(input, &saved_input_mode)
        || !GetConsoleMode(output, &saved_output_mode))
        return -1;                      /* not a console */
    saved_output_cp = GetConsoleOutputCP();

    /* Input: no line editing, no echo, no Ctrl+C signal; keys arrive as
     * escape sequences. */
    if (!SetConsoleMode(input, ENABLE_VIRTUAL_TERMINAL_INPUT))
        return -1;
    /* Output: interpret escape sequences, and do not move to the next
     * line by yourself. */
    if (!SetConsoleMode(output, ENABLE_PROCESSED_OUTPUT
                                | ENABLE_VIRTUAL_TERMINAL_PROCESSING
                                | DISABLE_NEWLINE_AUTO_RETURN)) {
        SetConsoleMode(input, saved_input_mode);
        return -1;
    }
    SetConsoleOutputCP(CP_UTF8);
    {
        DWORD ignored;

        WriteFile(output, enter, sizeof enter - 1, &ignored, NULL);
    }
    is_open = 1;

    if (!exit_hook_installed) {
        atexit(thuja_term_close);
        exit_hook_installed = 1;
    }
    return 0;
}

int thuja_term_size(int *columns, int *rows)
{
    CONSOLE_SCREEN_BUFFER_INFO info;

    if (!GetConsoleScreenBufferInfo(GetStdHandle(STD_OUTPUT_HANDLE), &info))
        return -1;
    *columns = info.srWindow.Right - info.srWindow.Left + 1;
    *rows = info.srWindow.Bottom - info.srWindow.Top + 1;
    return 0;
}

/* The console delivers input as records. In virtual-terminal mode each
 * key-down record carries one UTF-16 unit of the escape sequence. They
 * are read as records (never with ReadFile, which can block on a
 * key-up record) and re-encoded as UTF-8. */
int thuja_term_read(char *buffer, int max, int timeout_ms)
{
    INPUT_RECORD records[64];
    DWORD available = 0, count = 0, i;
    int n = 0;

    if (WaitForSingleObject(input, (DWORD)timeout_ms) != WAIT_OBJECT_0)
        return 0;
    if (!GetNumberOfConsoleInputEvents(input, &available))
        return -1;
    if (available == 0)
        return 0;
    if (available > 64)
        available = 64;
    /* Leave room: one record can become three bytes. */
    if (available > (DWORD)(max / 3))
        available = (DWORD)(max / 3);
    if (available == 0 || !ReadConsoleInputW(input, records, available, &count))
        return -1;

    for (i = 0; i < count; i++) {
        WCHAR unit;

        if (records[i].EventType != KEY_EVENT
            || !records[i].Event.KeyEvent.bKeyDown)
            continue;
        unit = records[i].Event.KeyEvent.uChar.UnicodeChar;
        if (unit == 0)
            continue;

        /* PLACEHOLDER: surrogate pairs (characters above U+FFFF) are
         * encoded one half at a time, which is not valid UTF-8. */
        if (unit < 0x80) {
            buffer[n++] = (char)unit;
        } else if (unit < 0x800) {
            buffer[n++] = (char)(0xC0 | (unit >> 6));
            buffer[n++] = (char)(0x80 | (unit & 0x3F));
        } else {
            buffer[n++] = (char)(0xE0 | (unit >> 12));
            buffer[n++] = (char)(0x80 | ((unit >> 6) & 0x3F));
            buffer[n++] = (char)(0x80 | (unit & 0x3F));
        }
    }
    return n;
}

int thuja_term_write(const char *buffer, int n)
{
    while (n > 0) {
        DWORD written = 0;

        if (!WriteFile(output, buffer, (DWORD)n, &written, NULL) || written == 0)
            return -1;
        buffer += written;
        n -= (int)written;
    }
    return 0;
}
