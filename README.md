# thuja

`thuja` is a terminal user interface (TUI) library written in Ada.

If you have never written a TUI before, think of it as a small GUI toolkit for a terminal. Instead of drawing
pixels into a window, you draw characters into a grid of terminal cells.

If you are new to Ada, that is expected. Start with [`Ada_for_Thuja.md`](Ada_for_Thuja.md). It explains the Ada
features used by this project with examples taken from the code.

This repository is the seed for a GNAT Academic Program capstone project. The project is intentionally incomplete:
the foundation is here, and the missing pieces are the work for the year.

## The idea in one minute

A `thuja` application owns one ordinary loop:

```ada
while not State.Quit loop
   Draw (Frame, State);          -- build the whole screen in memory
   Term.Present (Frame);         -- send only what changed
   Term.Poll (0.1, Event);       -- wait for keyboard/resize input
   Update (State, Event);        -- change application state
end loop;
```

There are four things to understand:

1. **State** is what the application remembers.
2. **Draw** turns that state into a complete screen-sized buffer.
3. **Present** compares the new buffer with the previous one and updates the real terminal.
4. **Poll** converts terminal bytes into typed events such as `Key_Down` or `Text_Input`.

That is the core of the project. There is no hidden event thread and no callback framework.

## What is a TUI?

A terminal is basically a rectangular grid:

```text
column 0                                          column 79
   v                                                  v
0  +--------------------------------------------------+
1  | Project: thuja                                   |
2  |                                                  |
3  | > Text Editor                                    |
4  |   Sort Visual                                    |
5  |   Keyboard                                       |
   +--------------------------------------------------+
^
row 0
```

Each position is a **cell**. A cell contains a character plus styling such as foreground colour, background colour,
bold, underline, and so on.

Applications do not directly print strings all over the terminal. They first draw into a `Thuja.Buffers.Buffer`.
The renderer then decides which terminal escape sequences are needed to make the physical terminal match that
buffer.

## Start here

For a new student, use this order:

1. Read [`Ada_for_Thuja.md`](Ada_for_Thuja.md).
2. Build the repository once.
3. Run the showcase.
4. Read `showcase/src/showcase.adb` from top to bottom.
5. Read [`ARCHITECTURE.md`](ARCHITECTURE.md).
6. Read the package spec (`.ads`) for the part you are going to change.
7. Read its tests before reading the implementation body (`.adb`).

Do **not** begin by reading every source file. You will understand less, not more.

## Build and run

You need [Alire](https://alire.ada.dev/), the Ada package manager.

From the repository root:

```sh
alr build
```

Run the showcase:

```sh
cd showcase
alr build
alr run
```

Press `q`, Escape, or Ctrl+C to quit.

If you do not have an interactive terminal, print a fixed frame instead:

```sh
cd showcase
alr run -a --snapshot
```

Run the tests:

```sh
cd tests
alr build
alr run
```

Run the SPARK proofs from the repository root:

```sh
alr with gnatprove
alr exec -- gnatprove -P thuja.gpr --mode=all
```

`alr with gnatprove` edits `alire.toml`. Do not commit that edit unless the team deliberately decides to pin the
prover dependency.

## The showcase is your map

`showcase/src/showcase.adb` is the smallest complete `thuja` application.

It contains the full pattern in one file:

```text
App_State
   |
   +--> Draw ------> Buffer ------> Terminal.Present ------> real terminal
   |
   +<-- Update <---- Event  <------ Terminal.Poll <--------- keyboard / resize
```

The screen is rebuilt from `App_State` every frame. `Draw` does not perform terminal I/O. `Update` does not draw.
That separation is important because it makes most of the project testable without a terminal.

## The main packages

You do not need to understand all of these on day one.

| Package | Plain-English job |
|---|---|
| `Thuja` | Basic geometry and project-wide limits |
| `Thuja.Buffers` | The in-memory screen made of cells |
| `Thuja.Styles` | Colours, bold, underline, etc. |
| `Thuja.UTF8` | Turn one Unicode character into UTF-8 bytes |
| `Thuja.Layout` | Split one rectangle into smaller rectangles |
| `Thuja.Input` | Turn raw terminal bytes into typed input events |
| `Thuja.Generic_Renderer` | Compare two frames and emit terminal bytes |
| `Thuja.Terminal` | The only package that talks to the operating system |
| `Thuja.Widgets.Blocks` | Borders and titles |
| `Thuja.Widgets.Labels` | One line of text |
| `Thuja.Widgets.Gauges` | Progress bar |
| `Thuja.Widgets.Generic_Lists` | Scrollable selectable list |

The important dependency rule is simple:

> High-level code may use lower-level packages. Low-level packages must not know about the application above them.

## What is already working

The seed is not a blank project. It already gives you enough working software to experiment safely.

| Area | Status |
|---|---|
| Geometry and frame bounds | working, proved |
| Buffer drawing and clipping | working, proved |
| Basic layout splitting | working, proved |
| Styles and UTF-8 output | working, proved |
| Basic input decoder | working but incomplete, proved |
| Renderer | correct but deliberately inefficient |
| POSIX terminal backend | working on Linux |
| Windows terminal backend | written, but needs real validation |
| Basic widgets | working |
| Showcase application | working |
| Unit tests | working and intentionally contain TODO milestones |
| `boxflex` adapter | partial |
| retained `escape` scene | design only |

## What you are expected to build

The exact planning is up to the team, but the project has five natural work areas.

### 1. Finish the input decoder

A terminal does not send a value called `Key_Right`. It sends bytes. For example:

```text
ESC [ C
```

means Right Arrow in a common terminal mode.

`Thuja.Input` turns those bytes into `Bedrock.Input.Event` values.

The seed already handles basic ASCII, Enter, Tab, Backspace, Escape, Ctrl+letter, Alt+letter/digit, arrows, Home,
and End. The tests mark missing behaviour with `Todo` calls.

Expected work includes:

- UTF-8 text input;
- function keys;
- Delete, Insert, Page Up and Page Down;
- modified keys such as Ctrl+Right;
- SS3 sequences;
- mouse input;
- bracketed paste.

This package is a SPARK proof target. New input behaviour needs tests **and** the existing safety properties must keep
proving.

### 2. Validate and finish Windows support

The Windows C backend compiles, but it has not been exercised enough on a real Windows Terminal session.

The goal is not to build a second TUI implementation. The Windows backend should expose the same small interface as
the POSIX backend so that all Ada code above it stays identical.

### 3. Make the renderer efficient

The application deliberately redraws the complete frame in memory. That should be simple for the application, not
expensive for the terminal.

The renderer compares the old frame with the new frame and sends only changes. The seed implementation is correct
but wasteful: a changed cell can cost roughly 30--45 bytes because it repeats cursor and style commands.

A good renderer should remember where the terminal cursor already is and which style is already active.

The showcase reports `Bytes_Presented`, so improvements are measurable.

### 4. Grow the widget set

The current widgets establish the pattern. Useful next widgets include:

- text input;
- button;
- tabs;
- table;
- scrollbar;
- multiline text area;
- focus navigation.

A widget is not a magical object managed by the framework. In the core library, it is mostly a `Draw` procedure.
Interactive widgets also have explicit state and a `Handle` procedure.

### 5. Rebuild the larger demos

The original `thuja` project had useful demonstrations: system monitor, text editor, flexbox playground, sorting
visualisation, sine wave, and keyboard viewer.

Those demos are the end-to-end goal. The higher-level scene/layout adapters are useful, but they must not block
progress. A demo written directly on the core loop is still a valid demo.

## The design rules that matter

These rules are part of the architecture, not arbitrary style choices.

- The **application owns the loop**. No callback-driven application model.
- Only `Thuja.Terminal` performs terminal I/O.
- No Ada task, access type, or heap allocation in `src/` without first discussing the architectural reason.
- Drawing must be safe for tiny, empty, or partially off-screen areas.
- Widgets draw only inside the rectangle they receive.
- Layout arithmetic belongs in `Thuja.Layout`, not scattered through widgets.
- New behaviour comes with a test, a proof, or both.
- Decoder changes require both tests and proof.
- Do not weaken contracts just to make GNATprove or a test pass.

The reason for these constraints is explained in [`ARCHITECTURE.md`](ARCHITECTURE.md).

## Tests are part of the specification

The test program is deliberately plain Ada. It does not need a unit-test framework to be useful.

The patterns are easy to copy:

```ada
Check ("Put clips at the right edge", Row (B, 1) = "      wx");
```

For unfinished seed behaviour:

```ada
Todo ("F5 (CSI 15 ~)", F5'Length = 1 and then Is_Key (F5 (1), Key_F5));
```

When your implementation makes a `Todo` pass, replace it with a `Check`. From then on, CI protects the behaviour.

## SPARK in this project

SPARK is the subset/tooling used to prove properties of Ada code.

For this project, the first thing to remember is much simpler than the theory:

> The proof is another build that must stay green.

You will see contracts such as:

```ada
with Pre  => In_Range (Area),
     Post => Inside (Split'Result (1), Area);
```

A `Pre` states what a caller must provide. A `Post` states what the subprogram guarantees when it returns.

The current SPARK units prove absence of run-time errors and selected project invariants. Read the contracts as useful
engineering documentation before thinking of them as formal-methods syntax.

## Where this project came from

The first `thuja` was built by Team 26 of SWENG 480 at Penn State Behrend: Skye Stout, David Gonzalez, Jacob
Norgard, and Sargis Poghosyan.

Original project: <https://github.com/TUI-Framework-Ada/thuja>

This repository is a second iteration. It keeps the strongest ideas—terminal diffing, flex-style layout, styling,
cross-platform support, and substantial demos—but simplifies the core around explicit state, typed events, tests,
and proof.

## Repository layout

```text
thuja/
├── src/                    core library
├── tests/                  terminal-free unit tests
├── showcase/               smallest complete application / acceptance test
├── adapters/
│   ├── boxflex/            richer layout adapter
│   └── escape/             retained scene design
├── Ada_for_Thuja.md        Ada + TUI primer for this project
├── ARCHITECTURE.md         how the pieces fit together
└── CONTRIBUTING.md         team workflow and engineering rules
```

## Technical references

For terminal control sequences, do not guess from examples found in random code:

- [ECMA-48](https://ecma-international.org/publications-and-standards/standards/ecma-48/) defines the control-sequence grammar.
- [XTerm Control Sequences](https://invisible-island.net/xterm/ctlseqs/ctlseqs.html) documents what common real terminals send and accept.

Reference environments for the project are xterm/POSIX and Windows Terminal/Windows.

## Contact

Olivier Henley, GAP Coordinator, AdaCore. Use the project Discord and the regular project meeting for design questions
that affect the architecture.

## License

Apache-2.0. See `LICENSE`.
