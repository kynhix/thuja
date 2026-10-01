--  THE RENDERER. Two frames in, the bytes that turn the first into the
--  second out.
--
--  The terminal is slow and far away; the application redraws its whole
--  frame every time. The renderer reconciles the two: it compares the
--  frame on screen with the new one and emits escape sequences only for
--  the cells that differ. An idle application emits nothing.
--
--  It is generic on where the bytes go, and does no I/O itself: the
--  terminal instantiates it with a write to stdout, the tests with an
--  append to a string. So what thuja would send to a terminal can be
--  checked byte for byte with no terminal.
--
--  PLACEHOLDER. The seed renderer is correct and wasteful: for every
--  changed cell it emits a cursor move, a full style and the character,
--  about 30 to 45 bytes. A good renderer emits a cursor move only when
--  the next changed cell is not the next cell, and a style only when
--  it differs from the one already in force; a line of typed text
--  should cost about one byte per character. Thuja.Terminal reports
--  the bytes of the last frame so the improvement can be measured.
--  Also missing: honouring terminals without 24-bit colour.

with Thuja.Buffers; use Thuja.Buffers;

generic
   with procedure Emit (Bytes : String);
package Thuja.Generic_Renderer is

   procedure Diff (Before, After : Buffer)
     with Pre => Before.Width >= After.Width
                 and then Before.Height >= After.Height;
   --  Emit what changes Before into After. Only the cells of After are
   --  compared; Before may be larger.

   procedure Full (After : Buffer);
   --  Emit After from nothing: clear the screen, then every cell that
   --  is not Blank. For the first frame and after a resize.

end Thuja.Generic_Renderer;
