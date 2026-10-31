with Thuja.Styles;  use Thuja.Styles;
with Thuja.Widgets.Blocks;
package body Thuja.Widgets.Text_Fields is

   ------------
   -- Handle --
   ------------
   procedure Handle (S : in out State; E : Event; Used : out Boolean) is

   begin
      Used := True;

      case E.Kind is
         when Key_Down =>
            case E.Key is
               when Key_Left =>
                  S.Cursor := Natural'Max (0, S.Cursor - 1);

               when Key_Right =>
                  S.Cursor := Natural'Min (Length (S.Text), S.Cursor + 1);

               --  Handle Moving to the start
               --  With either Home or Ctrl - A
               when Key_Home =>
                  S.Cursor := 0;
               when Key_A =>
                  if E.Mods.Ctrl
                  then
                     S.Cursor := 0;
                  end if;

               --  Handle Moving to the End
               --  With either End or Ctrl - E
               when Key_End =>
                  S.Cursor := Length (S.Text);
               when Key_E =>
                  if E.Mods.Ctrl
                  then
                     S.Cursor := Length (S.Text);
                  end if;

               when Key_Backspace =>
                  if S.Cursor > 0 and S.Cursor <= Length (S.Text) then
                     Delete (S.Text, From => S.Cursor, Through => S.Cursor);
                     S.Cursor := S.Cursor - 1;
                  end if;

               when others =>
                  Used := False;

            end case;

         when Text_Input =>
               Insert (S.Text, S.Cursor + 1, E.Text (1 .. E.Length));
               S.Cursor := S.Cursor + 1;

         when others =>
            Used := False;

      end case;
   end Handle;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Frame     : in out Buffer;
      Area      : Rect;
      S         : in out State;
      Title     : String)
   is
      Look  : constant Style := Thuja.Styles.Plain;
      Render_Text : Unbounded_String :=
         To_Unbounded_String (Get_Text (S));
      Row   : constant Rect :=
        Make (Area.Origin.X, Area.Origin.Y, Area.Extent.Width, 3);
   begin
      if Is_Empty (Area) or
         Area.Origin.Y < 3 -- only allow 3 so we can block it
      then
         return;
      end if;

      Fill (Frame, Row, (' ', Look));

      --  Draw the input's border and title
      Blocks.Draw (Frame, Row, Title);

      --  Inject cursor at specific point
      Insert (Render_Text, S.Cursor + 1, "|");

      Put (Frame, Row.Origin.X + 1, Row.Origin.Y + 1,
            To_String (Render_Text), Look, Clip => Row);
   end Draw;

   function Get_Text (S : State) return String is
   begin
      return To_String (S.Text);
   end Get_Text;

   procedure Set_Text (S : in out State; Text : String) is
   begin
      S.Text := To_Unbounded_String (Text);
      S.Cursor := Text'Length;
   end Set_Text;

end Thuja.Widgets.Text_Fields;
