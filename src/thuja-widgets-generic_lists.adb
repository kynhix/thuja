package body Thuja.Widgets.Generic_Lists is

   ------------
   -- Handle --
   ------------

   procedure Handle (S : in out State; E : Event; Used : out Boolean) is
      Last : constant Natural := Count;
   begin
      Used := False;

      if E.Kind /= Key_Down or else Last = 0 then
         return;
      end if;

      Used := True;

      case E.Key is
         when Key_Up =>
            S.Selected := Positive'Max (1, S.Selected - 1);

         when Key_Down =>
            S.Selected := Positive'Min (Last, S.Selected + 1);

         when Key_Home =>
            S.Selected := 1;

         when Key_End =>
            S.Selected := Last;

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
      Normal    : Style := Plain;
      Highlight : Style := Inverse (Plain))
   is
      Last    : constant Natural := Count;
      Visible : constant Natural := Natural (Area.Extent.Height);
      Index   : Natural;
   begin
      if Is_Empty (Area) or else Last = 0 then
         return;
      end if;

      --  Keep the state sane whatever happened to the rows or to the
      --  size of Area since the last frame.
      S.Selected := Positive'Min (S.Selected, Last);

      if S.Selected < S.Top then
         S.Top := S.Selected;
      elsif S.Selected - S.Top >= Visible then
         S.Top := S.Selected - Visible + 1;
      end if;

      for Line in 0 .. Visible - 1 loop
         Index := S.Top + Line;
         exit when Index > Last;

         declare
            Row   : constant Rect :=
              Make (Area.Origin.X, Area.Origin.Y + Pixels (Line), Area.Extent.Width, 1);
            Look  : constant Style := (if Index = S.Selected then Highlight else Normal);
         begin
            Fill (Frame, Row, (' ', Look));
            Put (Frame, Row.Origin.X + 1, Row.Origin.Y, Text (Index), Look, Clip => Row);
         end;
      end loop;
   end Draw;

end Thuja.Widgets.Generic_Lists;
