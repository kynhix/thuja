with Thuja;
with Thuja.Widgets.Blocks;
with Thuja.Layout;   use Thuja.Layout;

package body Demo.Text_Fields is

   package Blocks renames Thuja.Widgets.Blocks;

      procedure Draw_Field (Frame   : in out Buffer;
      Area    : Rect;
      S       : in out Text_Field.State;
      Title   : String;
      Focused : Boolean);

   ----------
   -- Draw --
   ----------

   overriding procedure Draw
     (D : in out State; Frame : in out Buffer; Area : Rect; Focused : Boolean)
   is
      Fields : constant Rect_Array :=
        Split
         (Area  => Blocks.Inner (Area),
          Along => Column,
          Items => [Fixed (3), Fixed (3), Fixed (3)],
          Gap   => 1);
   begin
      Blocks.Draw (Frame, Area, Title, Border (Focused));

      Draw_Field (Frame, Fields (1), D.Text_Fields (FirstName), "First Name",
            D.Focused = FirstName);
      Draw_Field (Frame, Fields (2), D.Text_Fields (LastName), "Last Name",
            D.Focused = LastName);
      Draw_Field (Frame, Fields (3), D.Text_Fields (Email), "Email",
            D.Focused = Email);
   end Draw;

   ------------
   -- Update --
   ------------

   overriding procedure Update (D : in out State; E : Event; Used : out Boolean) is
   begin
      if E.Kind = Key_Down and then
         E.Key = Key_Tab then
         --  Move focus to next in line
         if D.Focused = Field_Id'Last then
            D.Focused := Field_Id'First;
         else
            D.Focused := Field_Id'Succ (D.Focused);
         end if;
      end if;

      --  Offer the event to the widgets that exist
      Text_Field.Handle (D.Text_Fields (D.Focused), E, Used);
   end Update;

   --  Helper function to draw a text field with a border around it.
   procedure Draw_Field
   (Frame   : in out Buffer;
      Area    : Rect;
      S       : in out Text_Field.State;
      Title   : String;
      Focused : Boolean)
   is
   begin
      if Area.Extent.Height < 3
         or else Area.Extent.Width < 3
      then
         return;
      end if;

      Blocks.Draw
      (Frame, Area, Title, Border (Focused));

      Text_Field.Draw
      (Frame, Blocks.Inner (Area), S, Focused);
   end Draw_Field;

end Demo.Text_Fields;
