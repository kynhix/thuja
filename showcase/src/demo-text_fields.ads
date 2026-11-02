with Thuja.Widgets.Text_Fields;

package Demo.Text_Fields is
   package Text_Field renames Thuja.Widgets.Text_Fields;

   type State (Length : Positive) is new Instance with record
      Title : String (1 .. Length);
      FirstName : Text_Field.State;
      LastName  : Text_Field.State;
      Email     : Text_Field.State;
   end record;

   function Make (Title : String) return State
     with Pre => Title'Length > 0;

   overriding function Name (D : State) return String is (D.Title);
   overriding procedure Draw
     (D : in out State; Frame : in out Buffer; Area : Rect; Focused : Boolean);
   overriding procedure Update (D : in out State; E : Event; Used : out Boolean);
end Demo.Text_Fields;
