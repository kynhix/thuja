with Bedrock.Input; use Bedrock.Input;
with Thuja.Buffers; use Thuja.Buffers;

package Thuja.Widgets.Buttons is

   type State is record
      Activated : Boolean := False;
   end record;

   procedure Handle
     (S    : in out State;
      E    : Event;
      Used : out Boolean);

   function Was_Clicked
     (S : in out State) return Boolean;

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Text  : String)
     with Pre => In_Range (Area);

end Thuja.Widgets.Buttons;