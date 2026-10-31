--  One line of input text in an area
with Bedrock.Input; use Bedrock.Input;
with Thuja.Buffers; use Thuja.Buffers;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

package Thuja.Widgets.Text_Fields is
   type State is private;

   procedure Handle (S : in out State;
                     E : Event; Used :
                     out Boolean);
   --  Left, Right, Home and End move the selection.
   --  Alphanumeric and space will be entered into the input
   --  Any other event are used as false

   procedure Draw
     (Frame     : in out Buffer;
      Area      : Rect;
      S         : in out State;
      Title     : String)
     with Pre => In_Range (Area);
   --  Three rows row for the entire input box
   --  Along with a title

   function Get_Text (S :   State) return String;
   --  We're getting the text here

   procedure Set_Text (S : in out State; Text : String);
   --  Setting the text here

private

   type State is record
      Text    : Unbounded_String := To_Unbounded_String ("");
      Cursor  : Natural := 0; -- start at 0
   end record;
   --  Keep track of the internal state of the text Input
   --  Also keep track of where the cursor is in the input

end Thuja.Widgets.Text_Fields;