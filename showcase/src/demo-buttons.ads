with Thuja.Widgets.Buttons;

package Demo.Buttons is

   package Button renames Thuja.Widgets.Buttons;

   Title : constant String := "Buttons";

   type State is new Instance with record
      Click_Button : Button.State;
      Click_Count  : Natural := 0;
   end record;

   overriding function Name (D : State) return String is (Title);

   overriding procedure Draw
     (D       : in out State;
      Frame   : in out Buffer;
      Area    : Rect;
      Focused : Boolean);

   overriding procedure Update
     (D    : in out State;
      E    : Event;
      Used : out Boolean);

end Demo.Buttons;