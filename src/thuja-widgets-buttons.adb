with Thuja.Widgets.Blocks;
with Thuja.Widgets.Labels;
with Thuja.Styles; use Thuja.Styles;

package body Thuja.Widgets.Buttons is

   procedure Handle
     (S           : in out State;
      E           : Event;
      Used        : out Boolean;
      Was_Clicked : out Boolean)
   is
   begin
      Used := False;
      Was_Clicked := False;

      if not S.Enabled then
         S.Pressed := False;
         return;
      end if;

      if E.Kind = Key_Down and then E.Key = Key_Return then
         Was_Clicked := True;
         S.Pressed := True;
         Used := True;
      elsif E.Kind = Key_Up and then E.Key = Key_Return then
         S.Pressed := False;
         Used := True;
      elsif E.Kind = Key_Down or else E.Kind = Text_Input then
         S.Pressed := False;
      end if;
   end Handle;

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Text  : String;
      S     : in out State)
   is
      Border_Style : constant Style :=
        (if not S.Enabled then Dim (Plain)
         elsif S.Pressed then Bold (Plain)
         else Plain);
   begin
      if Area.Extent.Width < 2 or else Area.Extent.Height < 2 then
         return;
      end if;

      Thuja.Widgets.Blocks.Draw
        (Frame => Frame,
         Area  => Area,
         S     => Border_Style);

      Thuja.Widgets.Labels.Draw
        (Frame => Frame,
         Area  => Thuja.Widgets.Blocks.Inner (Area),
         Text  => Text,
         S     => Border_Style,
         Align => Thuja.Widgets.Labels.Center);

      S.Pressed := False;
   end Draw;

end Thuja.Widgets.Buttons;
