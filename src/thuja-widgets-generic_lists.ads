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

end Thuja.Widgets.Generic_Lists;
