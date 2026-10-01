/* The terminal, POSIX side. Five functions; Thuja.Terminal is the only
 * caller. Kept in C because the layout of struct termios differs
 * between Linux, macOS and the BSDs, and the C compiler already knows
 * it.
 *
 * Reference terminal: xterm. Tested on Linux only.
 */

#include <poll.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

/* Alternate screen on, cursor hidden / colours reset, cursor shown,
 * alternate screen off. The alternate screen is what gives the user
 * their shell contents back when the application leaves. */
static const char enter[] = "\x1b[?1049h\x1b[?25l";
static const char leave[] = "\x1b[0m\x1b[?25h\x1b[?1049l";

static struct termios saved;
static int is_open = 0;
static int exit_hook_installed = 0;

/* Back to the mode the terminal was in before thuja_term_open. */
void thuja_term_close(void)
{
    if (is_open) {
        ssize_t ignored = write(STDOUT_FILENO, leave, sizeof leave - 1);
        (void)ignored;
        tcsetattr(STDIN_FILENO, TCSAFLUSH, &saved);
        is_open = 0;
    }
}

/* Raw mode: no echo, no line editing, no signals from Ctrl+C, bytes
 * delivered as typed. Returns 0, or -1 if stdin/stdout is not a
 * terminal. */
int thuja_term_open(void)
{
    struct termios raw;

    if (is_open)
        return 0;
    if (!isatty(STDIN_FILENO) || !isatty(STDOUT_FILENO))
        return -1;
    if (tcgetattr(STDIN_FILENO, &saved) != 0)
        return -1;

    raw = saved;
    raw.c_iflag &= ~(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    raw.c_oflag &= ~(OPOST);
    raw.c_cflag |= CS8;
    raw.c_lflag &= ~(ECHO | ICANON | IEXTEN | ISIG);
    raw.c_cc[VMIN] = 0;
    raw.c_cc[VTIME] = 0;

    if (tcsetattr(STDIN_FILENO, TCSAFLUSH, &raw) != 0)
        return -1;
    if (write(STDOUT_FILENO, enter, sizeof enter - 1) < 0)
        return -1;
    is_open = 1;

    /* Last line of defence: if the program exits without closing, the
     * user still gets a usable shell back. */
    if (!exit_hook_installed) {
        atexit(thuja_term_close);
        exit_hook_installed = 1;
    }
    return 0;
}

/* Size in cells. Returns 0, or -1 if the terminal will not say. */
int thuja_term_size(int *columns, int *rows)
{
    struct winsize ws;

    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) != 0 || ws.ws_col == 0)
        return -1;
    *columns = ws.ws_col;
    *rows = ws.ws_row;
    return 0;
}

/* Wait up to timeout_ms for input, then read at most max bytes.
 * Returns the number of bytes read; 0 means nothing arrived in time;
 * -1 means the terminal is gone. */
int thuja_term_read(char *buffer, int max, int timeout_ms)
{
    struct pollfd fd = { STDIN_FILENO, POLLIN, 0 };
    int ready = poll(&fd, 1, timeout_ms);
    ssize_t n;

    if (ready <= 0)
        return 0;
    if (fd.revents & (POLLHUP | POLLERR | POLLNVAL))
        return -1;
    n = read(STDIN_FILENO, buffer, (size_t)max);
    return n < 0 ? 0 : (int)n;
}

/* Write all n bytes. Returns 0, or -1 on error. */
int thuja_term_write(const char *buffer, int n)
{
    while (n > 0) {
        ssize_t written = write(STDOUT_FILENO, buffer, (size_t)n);
        if (written <= 0)
            return -1;
        buffer += written;
        n -= (int)written;
    }
    return 0;
}
