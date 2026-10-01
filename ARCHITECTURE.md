# Architecture

This file explains how `thuja` works as a system.

If you are new to Ada, read [`Ada_for_Thuja.md`](Ada_for_Thuja.md) first. If you are new to TUIs, start with the
first three sections below before opening package bodies.

## 1. The whole machine

A `thuja` application repeatedly does four things:

```text
                 APPLICATION STATE
                        |
                        v
                 +--------------+
                 |     Draw     |
                 +--------------+
                        |
                        v
                Buffer / Frame
                        |
                        v
                 +--------------+
                 |   Present    |
                 +--------------+
                        |
                        v
                    TERMINAL
                        |
                   raw bytes
                        |
                        v
                 +--------------+
                 |     Poll     |
                 +--------------+
                        |
                        v
                  typed Event
                        |
                        v
                 +--------------+
                 |    Update    |
                 +--------------+
                        |
                        +-------> back to application state
```

In Ada, that looks roughly like this:

```ada
while not State.Quit loop
   declare
      Now   : constant Size := Term.Size;
      Frame : Buffer (Now.Width, Now.Height);
   begin
      Draw (Frame, State);
      Term.Present (Frame);
   end;

   Term.Poll (Timeout => 0.1, E => E);
   Update (State, E);
end loop;
```

The application owns this loop. `thuja` never calls a hidden application callback and never runs a background Ada
task.

That one decision makes the rest of the design easier to reason about: application state is visible, input arrives at
a known point, and drawing happens at a known point.

## 2. Why redraw the whole screen?

At first this may sound wasteful.

Suppose the application has a list and the selected row moves from 3 to 4. One design would make the application
remember which cells changed and issue terminal commands itself.

`thuja` does not do that.

Instead:

1. The application draws a complete new frame in memory.
2. `Thuja.Generic_Renderer` compares the old and new frames.
3. Only changed cells are sent to the real terminal.

So the application can stay simple:

```ada
Draw_List (Frame, Current_State);
```

rather than maintaining two versions of reality: its own state plus a manual record of what it believes is already on
screen.

## 3. Follow one key press through the system

Imagine the user presses the Up Arrow.

### Step A: the terminal produces bytes

A common terminal sends:

```text
1B 5B 41
```

Those are hexadecimal byte values for:

```text
ESC [ A
```

### Step B: `Thuja.Input` decodes the bytes

`Thuja.Input.Feed` receives one byte at a time. Its small state machine eventually recognizes the sequence and
produces a typed `Bedrock.Input.Event`:

```text
Kind = Key_Down
Key  = Key_Up
```

The rest of the application no longer needs to know anything about `ESC [ A`.

### Step C: `Update` changes application state

For the showcase list, the event is passed to:

```ada
Demo_Lists.Handle (State.Demos, E, Used);
```

The list changes its `Selected` field.

### Step D: `Draw` builds a new frame

On the next loop iteration, `Draw` redraws the list from its new state. The highlighted row is now different.

### Step E: the renderer sends the smallest terminal update it can

`Present` compares the previous frame with the new one. Only changed cells need to be emitted.

That is one complete trip through `thuja`.

## 4. The frame: `Thuja.Buffers`

A frame is a `Buffer`:

```ada
Frame : Buffer (80, 24);
```

This means 80 columns by 24 rows.

A cell contains:

```ada
type Cell is record
   Glyph : Wide_Wide_Character := ' ';
   Style : Styles.Style        := Plain;
end record;
```

So every screen position has both a character and a style.

Coordinates use the usual terminal convention:

```text
(0,0) -----------------> X / columns
  |
  |
  |
  v
 Y / rows
```

### Drawing clips instead of failing

This is a fundamental rule of the library.

If you draw text partly outside the frame:

```ada
Put (Frame, X => 78, Y => 2, Text => "hello", ...);
```

on an 80-column frame, only the part that fits is drawn.

If a widget receives an empty area, it draws nothing.

If an area is partly off-screen, only the visible part is drawn.

This matters because terminal windows can become very small. Resizing should make the interface cramped, not crash
the program with `Constraint_Error`.

### Why `Buffer` has `(Width, Height)` in its type

`Buffer` is an Ada **discriminated type**:

```ada
type Buffer (Width : Column_Count; Height : Row_Count) is private;
```

The dimensions are part of each buffer object. A new frame can therefore be declared directly from the current
terminal size:

```ada
Now   : constant Size := Term.Size;
Frame : Buffer (Now.Width, Now.Height);
```

No heap allocation is required.

The current seed treats every Unicode character as one terminal column. Correct handling of double-width characters
and combining marks is future work.

## 5. Geometry and layout: `Thuja` + `Thuja.Layout`

The root `Thuja` package provides rectangle helpers such as:

```ada
Make
Inside
Intersection
Inset
Right
Bottom
```

`Thuja.Layout.Split` is the normal way to divide screen space.

Example:

```ada
Bands : constant Rect_Array :=
  Split (Area (Frame), Column, [Fixed (3), Flex, Fixed (3)]);
```

Read this as:

> Split the screen vertically into three bands: 3 rows, all remaining rows, then 3 rows.

There is one naming detail that often confuses new readers:

- `Row` means place items **left to right** in one row.
- `Column` means place items **top to bottom** in one column.

That matches flexbox vocabulary. It describes the direction in which the items are laid out, not the shape of the
rectangle being cut.

Another example:

```ada
Panes : constant Rect_Array :=
  Split (Bands (2), Row, [Fixed (24), Flex]);
```

This produces a 24-column left pane and a right pane that takes the remaining width.

`Split` guarantees that its results remain inside the input area. When there is not enough room, items shrink or
become empty rather than escaping the container.

## 6. Widgets are deliberately simple

A stateless widget is mostly a `Draw` procedure.

For example:

```ada
Labels.Draw (Frame, Area, "hello");
```

There is no hidden widget object registered with a framework. A widget exists on a frame because the application
called its `Draw` procedure.

The seed has:

- `Blocks`: border and optional title;
- `Labels`: one line of text;
- `Gauges`: horizontal progress bar;
- `Generic_Lists`: scrollable selected list.

### Interactive widgets keep explicit state

The list has:

```ada
type State is record
   Selected : Positive := 1;
   Top      : Positive := 1;
end record;
```

The application owns an instance of that state:

```ada
type App_State is record
   Demos : Demo_Lists.State;
   ...
end record;
```

Input is offered explicitly:

```ada
Demo_Lists.Handle (State.Demos, E, Used);
```

That `State + Handle + Draw` pattern is the model for future interactive widgets.

## 7. Input: `Thuja.Input`

This package sits between raw terminal bytes and the typed event model.

Its public interface is intentionally small:

```ada
Feed    -- give it one byte
Pending -- ask whether a sequence is unfinished
Flush   -- tell it no more bytes arrived for now
```

### Why Escape is difficult

The byte `16#1B#` can mean two things:

- the user pressed the Escape key;
- an escape sequence is beginning.

When the decoder receives only `1B`, it cannot know yet.

So it waits in a pending state. `Thuja.Terminal` waits briefly for another byte. If none arrives, it calls `Flush`,
and the lone byte becomes `Key_Escape`.

This is also what makes Alt combinations possible: terminals commonly encode Alt+x as Escape followed by `x`.

### What the seed currently handles

The seed handles the small useful core: ASCII text, common control keys, arrows, Home/End, Ctrl+letter, and
Alt+letter/digit.

The test suite already contains `Todo` cases for the next behaviours. Work outward from those tests instead of
inventing a second list of requirements.

### Proof obligations

`Thuja.Input` is a main SPARK target. The important properties are:

1. Any possible byte stream must be safe: no run-time error.
2. Decoder memory stays bounded by `Max_Sequence`.
3. `Flush` always leaves the decoder out of a pending state.

A malformed or unknown terminal sequence is ordinary input, not an exceptional condition.

## 8. Rendering: `Thuja.Generic_Renderer`

The renderer converts frame differences back into terminal bytes.

Its main operations are:

```ada
Diff (Before, After)
Full (After)
```

`Diff` is used for normal updates. `Full` is used when there is no valid previous frame, such as initial display or
a resize.

### Why it is generic

The renderer needs to **emit bytes**, but it should not own terminal I/O.

So the package is generic:

```ada
generic
   with procedure Emit (Bytes : String);
package Thuja.Generic_Renderer is
   ...
end Thuja.Generic_Renderer;
```

The real terminal instantiates it with a procedure that writes bytes out. The tests instantiate it with a procedure
that appends bytes to a string.

Same renderer, two destinations.

This is why the renderer can be tested byte-for-byte without opening a terminal.

### The current optimisation problem

The seed renderer repeats too much state. For each changed cell it can emit:

1. a cursor move;
2. a full style command;
3. the character;
4. eventually a reset.

A better renderer tracks its own output state while traversing the diff:

- Where is the cursor now?
- What style is active now?
- Is the next changed cell adjacent?

Correctness comes first. Optimisation must preserve two existing safety rules:

- control characters stored in cells may never become terminal commands;
- a frame that changes terminal style must leave the terminal style reset afterward.

## 9. Terminal I/O: `Thuja.Terminal`

`Thuja.Terminal` is the only core Ada package that performs I/O.

A `Session` provides:

```text
Open
Close
Size
Poll
Present
Bytes_Presented
```

Below the Ada package are two small C backends:

```text
src/posix/thuja_term.c
src/windows/thuja_term.c
```

They handle the operating-system-specific operations such as raw terminal mode, reads with timeout, writes, and
terminal size.

The Ada code above those backends should not care whether it is on Linux or Windows.

### Why `Session` is a controlled type

A terminal application can leave the user's shell in a bad state if it enables raw mode and exits without restoring
it.

`Session` derives from `Ada.Finalization.Limited_Controlled`. Its `Finalize` operation closes the session when the
Ada object leaves scope.

There is also a lower-level process exit hook for cases where normal Ada cleanup cannot run.

The intent is simple: failures in the application should not leave the user's terminal unusable.

## 10. Styles and UTF-8

`Thuja.Styles` stores colours and attributes as ordinary typed data:

```ada
type Style is record
   Foreground : Color;
   Background : Color;
   Attr       : Attributes;
end record;
```

Helpers make styles readable:

```ada
Accent : constant Style := Bold (Colored (Bedrock.Colors.Sky_Blue));
```

`Thuja.UTF8` performs the opposite boundary conversion from `Thuja.Input`: it turns a Unicode character held in a
cell into the UTF-8 bytes a terminal expects.

## 11. What is pure, and what is effectful?

A useful mental division is:

```text
Mostly computation / testable without a terminal
-------------------------------------------------
geometry
buffers
layout
styles
UTF-8 encoding
input decoding
widgets
renderer logic

Actual external I/O
-------------------
Thuja.Terminal
POSIX / Windows C backend
```

The renderer produces bytes but does not decide where those bytes go. That is why it remains easy to test.

When adding new code, keep logic above the I/O boundary whenever possible.

A good diagnostic question is:

> Could I test this behaviour using only values in memory?

If yes, it probably does not belong in `Thuja.Terminal`.

## 12. Contracts and SPARK

You will see declarations such as:

```ada
procedure Draw (...)
  with Pre => In_Range (Area);
```

and:

```ada
function Inset (...) return Rect
  with Post => Inside (Inset'Result, R);
```

For day-to-day work, read these literally:

- **Precondition:** what must already be true when you call this operation.
- **Postcondition:** what this operation promises will be true when it returns.

Contracts are checked at runtime in project builds, and SPARK also uses them for proof.

Do not remove a contract because new code cannot prove. Determine whether the implementation is wrong, the caller is
wrong, or the contract itself genuinely needs correction.

## 13. Testing strategy

The project is designed so most failures can be reproduced without a terminal.

### Test a decoder sequence

Feed bytes from a string and inspect the returned events.

### Test drawing

Draw into a tiny buffer and compare a row with expected text.

```ada
Check ("label", Row (B, 1) = "|hello         |");
```

### Test rendering

Instantiate the generic renderer with a collector and compare the exact byte string.

### Test the whole application

Run:

```sh
cd showcase
alr run -a --snapshot
```

The snapshot is also usable in CI because it does not require an interactive terminal.

## 14. The higher-level adapters

The core library deliberately stops before becoming a complete retained GUI framework.

Two adapters explore higher-level composition.

### `adapters/boxflex`

This connects `thuja` to a richer flexbox-style layout engine. It is intended to provide nested layouts, wrapping,
alignment, and shrinking beyond the simple `Split` helper.

### `adapters/escape`

This is the planned retained scene layer: interface elements become entities with typed components, and systems
perform layout, painting, and event dispatch.

It is not required for basic applications. Read `adapters/escape/README.md` only when working on that milestone.

The dependency direction remains:

```text
application / scene
        |
        v
widgets + layout
        |
        v
buffers / input / renderer
        |
        v
terminal boundary
```

The core must not acquire dependencies on the higher-level scene.

## 15. Known limits of the seed

These are current engineering limits, not properties to accidentally depend on forever:

- one terminal column is assumed per character;
- 24-bit colour is always emitted;
- no complete UTF-8 input path yet;
- no complete mouse or bracketed-paste handling yet;
- Windows needs real-world validation;
- frame dimensions are bounded to 400 x 150 cells;
- the retained scene is not implemented.

## 16. Before changing a subsystem

Use this sequence:

1. Read its `.ads` file.
2. Find its tests.
3. Run the tests before changing anything.
4. Make the smallest useful behaviour change.
5. Add or convert a test in the same change.
6. Run `alr build` and the tests.
7. If it is SPARK code, run GNATprove.
8. Only then refactor or optimise.

That keeps the project in a state where the next student can still understand what happened.
