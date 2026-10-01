# Ada for Thuja

This is not an Ada course. It is the small amount of Ada you need to start reading and changing `thuja`.

If you already know C++, Rust, Java, C#, or another typed language, most ideas are familiar. Ada is simply more
explicit about types, ranges, parameter direction, and contracts.

Keep `showcase/src/showcase.adb` open while reading this file. Nearly every example below appears there or in one of
the core package specs.

## 1. `.ads` is the interface, `.adb` is the implementation

Ada normally separates a package into two files:

```text
thuja-buffers.ads   public interface: what callers can use
thuja-buffers.adb   package body:     how it works
```

Start with the `.ads` file.

```ada
package Thuja.Buffers is
   procedure Clear (B : in out Buffer);
end Thuja.Buffers;
```

The body implements it:

```ada
package body Thuja.Buffers is
   procedure Clear (B : in out Buffer) is
   begin
      ...
   end Clear;
end Thuja.Buffers;
```

For this project, **read the spec and tests before the body**.

## 2. `with`, `use`, and package names

`with` makes another package available:

```ada
with Thuja.Buffers;
```

You can then write the full name:

```ada
Thuja.Buffers.Buffer
```

With `use`:

```ada
with Thuja.Buffers; use Thuja.Buffers;
```

you can simply write:

```ada
Buffer
```

The showcase also creates short package aliases:

```ada
package Blocks renames Thuja.Widgets.Blocks;
```

so this:

```ada
Blocks.Draw (...)
```

means exactly the same thing as `Thuja.Widgets.Blocks.Draw (...)`.

## 3. Declarations read `Name : Type`

```ada
Failures : Natural := 0;
Used     : Boolean;
```

Constants are explicit:

```ada
Max_Columns : constant := 400;
Accent      : constant Style := Bold (Colored (Bedrock.Colors.Sky_Blue));
```

Ada uses strong types heavily. Do not assume two integer-looking values are interchangeable just because both are
stored as numbers.

## 4. Ranges are part of the design

A subtype can restrict legal values:

```ada
subtype Percent is Natural range 0 .. 100;
```

So a gauge takes:

```ada
Value : Percent;
```

not "any integer and we hope it is valid."

You will see the same idea for terminal sizes, indexes, decoder lengths, and coordinates. Treat the ranges as useful
engineering documentation.

## 5. Records are structs

```ada
type App_State is record
   Last_Event : Event   := No_Event;
   Frames     : Natural := 0;
   Quit       : Boolean := False;
end record;
```

Access fields with a dot:

```ada
State.Quit := True;
State.Frames := State.Frames + 1;
```

Record aggregates often use field names:

```ada
(Ctrl => True, others => False)
```

This means `Ctrl = True` and all remaining fields use `False`.

## 6. `in`, `out`, and `in out` tell you where mutation happens

```ada
procedure Update (State : in out App_State; E : Event);
```

Read it as:

- `State` is read and modified;
- `E` is input only (`in` is the default).

Another example:

```ada
procedure Handle (S : in out State; E : Event; Used : out Boolean);
```

`Used` is produced by the procedure.

When reading unfamiliar Ada, parameter modes are one of the fastest ways to see where state can change.

## 7. Functions return values; procedures perform operations

```ada
function Right (R : Rect) return Integer;
procedure Clear (B : in out Buffer);
```

Small functions may be written as one expression:

```ada
function Is_Empty (R : Rect) return Boolean is
  (R.Extent.Width = 0 or else R.Extent.Height = 0);
```

`and then` and `or else` are the short-circuit Boolean operators.

```ada
if E.Kind = Key_Down and then E.Key = Key_Escape then
   ...
end if;
```

The right side is evaluated only when needed.

## 8. Arrays do not have to start at zero

```ada
type Event_List is array (Positive range <>) of Event;
```

`<>` means the concrete bounds are supplied later.

Useful attributes are:

```ada
A'First
A'Last
A'Length
```

Modern Ada also has compact array aggregates:

```ada
[Fixed (3), Flex, Fixed (3)]
```

That is what you see in layout calls:

```ada
Split (Area, Column, [Fixed (3), Flex, Fixed (3)])
```

## 9. `Buffer (80, 24)` is a discriminated type

The buffer declaration is:

```ada
type Buffer (Width : Column_Count; Height : Row_Count) is private;
```

`Width` and `Height` are **discriminants**: values attached to each buffer object that determine its shape.

So:

```ada
Frame : Buffer (80, 24);
```

is an 80 x 24 frame, while the real application can use the current terminal size:

```ada
Now   : constant Size := Term.Size;
Frame : Buffer (Now.Width, Now.Height);
```

No heap allocation is needed for the frame.

## 10. `declare` makes a small local scope

The showcase contains this pattern:

```ada
declare
   Now   : constant Size := Term.Size;
   Frame : Buffer (Now.Width, Now.Height);
begin
   Draw (Frame, State);
   Term.Present (Frame);
end;
```

`Frame` exists only inside this block. That is useful because a fresh frame is built for each loop iteration.

## 11. `case` is used heavily for typed events

```ada
case E.Kind is
   when Key_Down =>
      ...

   when Text_Input =>
      ...

   when others =>
      null;
end case;
```

`null;` means "do nothing."

You also see `case` expressions that directly return a value:

```ada
(case Index is
    when 1 => "HTop",
    when 2 => "Text Editor",
    when others => "Keyboard")
```

## 12. Ada attributes: `'Image`, `'Val`, `'Pos`

Ada types expose useful built-in attributes.

Convert a value to display text:

```ada
E.Kind'Image
```

Create a character from its numeric code:

```ada
Character'Val (16#1B#)
```

Get a character's numeric code:

```ada
Wide_Wide_Character'Pos (C)
```

`16#1B#` is hexadecimal notation for `0x1B`.

That byte is Escape, so you will see it often in terminal code.

## 13. Generics: reusable code with typed parameters

The list widget does not own your application's rows. It asks you to provide two functions:

```ada
generic
   with function Count return Natural;
   with function Text (Index : Positive) return String;
package Thuja.Widgets.Generic_Lists is
   ...
end Thuja.Widgets.Generic_Lists;
```

The showcase provides:

```ada
function Demo_Count return Natural is (6);
function Demo_Name (Index : Positive) return String is (...);
```

and creates a concrete list package:

```ada
package Demo_Lists is new Thuja.Widgets.Generic_Lists
  (Count => Demo_Count, Text => Demo_Name);
```

After that, `Demo_Lists.State`, `Demo_Lists.Draw`, and `Demo_Lists.Handle` are ordinary typed declarations.

The renderer uses the same Ada feature for another purpose: its generic parameter is the procedure that receives
output bytes.

## 14. Contracts: `Pre` and `Post`

You will see declarations such as:

```ada
procedure Draw (...)
  with Pre => In_Range (Area);
```

Read it literally: the caller must provide an `Area` satisfying `In_Range`.

A postcondition states what the operation guarantees:

```ada
function Inset (...) return Rect
  with Post => Inside (Inset'Result, R);
```

`Inset'Result` means the function's returned value.

The project checks contracts at runtime and also uses them in SPARK proof.

If a contract fails, do not immediately remove it. First decide whether the caller, implementation, or contract is
actually wrong.

## 15. SPARK mode

Some packages say:

```ada
package Thuja.Layout with SPARK_Mode is
```

GNATprove analyzes those packages.

For a new student, the useful rule is simply:

> Keep the code inside its declared ranges and contracts, and keep the proof command green.

When proof fails, read the failing check. It often exposes a real array-bound, range, or arithmetic question.

## 16. Private types hide internal state

The decoder is declared:

```ada
type Decoder is private;
```

Callers may store it and pass it to `Feed`, `Pending`, and `Flush`, but cannot reach into its fields directly.

That lets `Thuja.Input` protect its state-machine invariants.

The same idea is used for `Buffer` and `Terminal.Session`.

## 17. One TUI fact: the terminal speaks bytes, not widgets

When the user presses Up Arrow, a common terminal sends bytes such as:

```text
ESC [ A
```

`Thuja.Input` turns those bytes into a typed event:

```text
Kind = Key_Down
Key  = Key_Up
```

Going the other way, the renderer sends byte sequences that mean things such as:

```text
move cursor
set colour
print character
reset style
```

So the project has two clean conversions:

```text
terminal bytes ---> Thuja.Input ---> typed Event

Frame difference ---> Generic_Renderer ---> terminal bytes
```

Most of your code should live between those boundaries and deal with typed values, not raw escape sequences.

## 18. Another TUI fact: drawing happens in memory first

A `thuja` widget does not print directly to the terminal.

It receives a `Buffer` and an `Area`:

```ada
Labels.Draw (Frame, Area, "hello");
```

The widget changes cells in memory. Later, `Term.Present (Frame)` updates the real terminal.

This is why widgets can be tested without opening a terminal.

It also explains the main application structure:

```text
State  -- what the program remembers
Draw   -- State -> complete frame
Update -- State + Event -> new State
```

When you get lost in an application, find those three things first.

## 19. Controlled terminal cleanup

`Terminal.Session` is a `limited` controlled type internally.

You do not need to master Ada finalization to use it. The important effect is:

> when a session leaves scope, `thuja` gets a chance to restore the terminal.

That matters because a TUI temporarily changes terminal mode. A failed program should not leave the user's shell in
raw mode.

## 20. A good first exercise

Before taking a major subsystem, make one tiny change end to end:

1. Add a counter field to `App_State` in the showcase.
2. Draw it with `Labels.Draw`.
3. Increment it for some event in `Update`.
4. Build and run the showcase.

Then make one tiny widget:

1. Give it a `Draw (Frame, Area, ...)` procedure.
2. Draw only through `Thuja.Buffers` operations.
3. Test it in a small buffer by comparing rows as text.

After those two exercises, most of the project structure should stop feeling foreign.

## What you do not need first

Do not wait until you know all of Ada.

The core intentionally avoids many advanced features. You can postpone tasking, protected objects, access types,
storage pools, advanced tagged dispatch, and most formal-proof theory until the project gives you a real reason to
learn them.
