# `thuja_scene`: the retained UI layer

> Status: design only. This is a later project milestone, not the place to start learning `thuja`.

The core `thuja` API is **immediate mode**: every frame, the application directly calls the widgets it wants to draw.

For example:

```ada
Blocks.Draw (Frame, Panel_Area, "Settings");
Labels.Draw (Frame, Text_Area, "Name");
```

That is simple and works well for small tools.

A larger application may want a **retained scene** instead: create interface nodes once, store their components, then
let a few systems walk those components every frame.

This adapter is the design for that layer. It combines:

- `thuja` for drawing widgets and terminal interaction;
- `boxflex` for layout;
- `escape` for typed entities/components.

The core `thuja` library must remain usable without this adapter.

## Immediate mode vs retained mode

### Immediate mode: what the showcase does

The application says what exists every frame:

```text
Draw frame
  draw header
  draw list
  draw event panel
  draw footer
```

There is no persistent widget tree.

### Retained mode: what this adapter is for

The application stores nodes such as:

```text
Entity 1: Node + Frame
Entity 2: Node + Text + Focus
Entity 3: Node + Level
```

Then systems process the scene:

```text
Layout system   -> calculate rectangles
Paint system    -> call thuja widget Draw procedures
Dispatch system -> route keyboard input to the focused entity
```

The difference is mostly about **where the structure of the interface lives**.

## The component types

The initial component records are in `src/thuja_scene.ads`.

| Component | Meaning |
|---|---|
| `Node` | where this entity sits in the boxflex layout tree |
| `Frame` | draw a bordered block with a title/style |
| `Text` | draw text with a style/alignment |
| `Level` | draw a percentage gauge |
| `Focus` | place this entity in keyboard focus order |

An entity's behaviour comes from the combination of components it has.

For example:

```text
Node + Frame
```

can represent a panel, while:

```text
Node + Text + Focus
```

could become a focusable text/button-like element.

The point is to keep component data typed. We do not want component names passed around as strings.

## One frame of a scene

The planned application loop still belongs to the application. The scene does not create another hidden event loop.

A frame should roughly be processed in this order.

### 1. Layout

Compute the boxflex tree for the current terminal size:

```ada
Thuja_Boxflex.Compute (Tree, Term.Size);
```

Each `Node` then maps to a terminal rectangle.

### 2. Paint

Walk entities and call normal `thuja` widgets using those rectangles.

Conceptually:

```text
for each entity with Node + Frame
    Blocks.Draw (...)

for each entity with Node + Text
    Labels.Draw (...)

for each entity with Node + Level
    Gauges.Draw (...)
```

The scene does not need a second drawing API. It reuses the core widgets.

### 3. Dispatch input

Poll one `Bedrock.Input.Event` from the terminal.

Then:

- Tab changes focus;
- other relevant input is offered to the focused interactive entity;
- unhandled events may continue to application-level logic.

The exact dispatch model is part of the remaining design work.

## Why this is above the core

Dependency direction matters:

```text
thuja_scene
   | \
   |  +--> escape
   +-----> boxflex
   +-----> thuja

thuja  -X-> thuja_scene
```

`thuja` must not know that a retained scene exists. A small application should still be able to use only a buffer,
layout, widgets, and the terminal loop.

## Questions the team must answer

This adapter intentionally leaves several design questions open.

### Text storage

The current `Text_Data.Content` uses `Bedrock.Names.Name`, which is bounded.

That is fine for short labels, but not for an editor or arbitrary text. Decide whether scene components should:

- keep bounded names only for short UI labels;
- hold handles into a separate text store;
- use different component types for labels and editable text.

Do not introduce heap ownership casually just because a label eventually needs more than 32 characters.

### Stateful widgets

`Thuja.Widgets.Generic_Lists` has a `State`, while its row source is provided through generic functions.

For a retained scene, decide where both pieces live:

- list selection/scroll state;
- the collection supplying row count and row text.

The answer should work for more than the showcase's fixed list of demo names.

### Removing layout nodes

The current boxflex tree design is append-oriented. A scene needs a clear story for entity removal.

Possible directions include:

- rebuild the layout tree from retained components when structure changes;
- add safe node removal to boxflex;
- use a scene-owned mapping that can be regenerated.

Measure before building a complicated lifetime system. A TUI with a few hundred nodes has very different needs from a
web browser DOM.

## If `escape` is not ready

Do not block the capstone on another repository.

You can prototype the same architecture with a bounded array:

```text
Node 1: optional Frame, optional Text, optional Focus, ...
Node 2: optional Frame, optional Level, ...
...
```

Use the array index as the temporary entity id and write the same three passes: layout, paint, dispatch.

If the component boundaries are sound, replacing the storage mechanism later should not require rewriting every
widget.

You may also skip the retained scene entirely for a demo and build it directly with the core `thuja` loop. A working,
tested demo is more valuable than a stalled framework.

## Completion target

This milestone is successful when substantial demos from the first `thuja` can be expressed as scenes on both Linux
and Windows, with snapshot/regression tests where practical.

The retained scene is a means to make larger applications easier to assemble. It is not the end product by itself.
