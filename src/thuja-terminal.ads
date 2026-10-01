--  The terminal: the one package that does I/O.
--
--  An application's whole contact with the terminal is three calls in a
--  loop:
--
--     Poll     wait for the next event (a key, a resize), or a timeout
--     (draw the frame into a Thuja.Buffers.Buffer)
--     Present  show that frame; only the cells that changed are sent
--
--  No task, no callback: the application owns the loop, and nothing
--  happens behind its back.
--
--  Opening a session puts the terminal in raw mode on its alternate
--  screen. Closing it gives the user their shell back exactly as it
--  was. A Session closes itself when it goes out of scope, and the
--  process restores the terminal on exit even if it never got there,
--  so a crash does not leave the user with a dead terminal.
--
--  There is one terminal per process, so at most one Session is open
--  at a time.
--
--  The body is the same on every system. What differs lives in
--  src/posix/thuja_term.c and src/windows/thuja_term.c.

private with Ada.Finalization;

with Bedrock.Input;
with Thuja.Buffers;

package Thuja.Terminal is

   Not_A_Terminal : exception;
   --  Standard input or output is not an interactive terminal (a pipe,
   --  a file, a CI job).

   type Session is tagged limited private;

   procedure Open (S : in out Session)
     with Pre => not Is_Open (S), Post => Is_Open (S);
   --  Raises Not_A_Terminal. Raises Program_Error if another Session
   --  is open.

   procedure Close (S : in out Session)
     with Post => not Is_Open (S);
   --  Does nothing if S is not open.

   function Is_Open (S : Session) return Boolean;

   function Size (S : Session) return Bedrock.Screen.Size
     with Pre  => Is_Open (S),
          Post => Size'Result.Width in 1 .. Max_Columns
                  and then Size'Result.Height in 1 .. Max_Rows;
   --  The terminal's size in cells, now.

   procedure Poll
     (S       : in out Session;
      Timeout : Duration;
      E       : out Bedrock.Input.Event)
     with Pre => Is_Open (S) and then not E'Constrained;
   --  The next event. E.Kind is None if nothing happened within
   --  Timeout. A resize arrives as Window_Resized with the new size.
   --  Quit means the terminal itself is gone.

   procedure Present (S : in out Session; Frame : Buffers.Buffer)
     with Pre => Is_Open (S);
   --  Make the terminal show Frame.

   function Bytes_Presented (S : Session) return Natural;
   --  How many bytes the last Present sent. The renderer's score:
   --  smaller is better.

private

   type Session is new Ada.Finalization.Limited_Controlled with record
      Active : Boolean := False;
   end record;

   overriding procedure Finalize (S : in out Session);

   function Is_Open (S : Session) return Boolean is (S.Active);

end Thuja.Terminal;
