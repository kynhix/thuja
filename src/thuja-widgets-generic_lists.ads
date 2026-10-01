--  A list of rows, one of them selected, that scrolls to keep the
--  selection visible. The pattern for every widget with state.
--
--  The list does not own the rows. It asks for them, one at a time,
--  through the two generic formals, and only for the rows it shows:
--  a list of a hundred thousand processes costs the same as a list of
--  ten.

with Bedrock.Input; use Bedrock.Input;
with Thuja.Buffers; use Thuja.Buffers;
with Thuja.Styles;  use Thuja.Styles;

generic
   with function Count return Natural;
   --  How many rows there are, now.

   with function Text (Index : Positive) return String;
   --  The text of row Index, for Index in 1 .. Count.
package Thuja.Widgets.Generic_Lists is

   type State is record
      Selected : Positive := 1;
      Top      : Positive := 1;
   end record;
   --  Selected: the highlighted row. Top: the first row on screen.
   --  The application keeps one State per list and may read or set
   --  Selected at any time.

   procedure Handle (S : in out State; E : Event; Used : out Boolean);
   --  Up, Down, Home and End move the selection. Used is False for any
   --  other event, which the application may then give to someone else.

   procedure Draw
     (Frame     : in out Buffer;
      Area      : Rect;
      S         : in out State;
      Normal    : Style := Plain;
      Highlight : Style := Inverse (Plain))
     with Pre => In_Range (Area);
   --  One row per line of Area. S is corrected first: Selected is
   --  brought back into 1 .. Count, and Top moved so that the selected
   --  row is inside Area.

end Thuja.Widgets.Generic_Lists;
