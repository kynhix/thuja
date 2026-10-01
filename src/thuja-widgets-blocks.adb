package body Thuja.Widgets.Blocks with SPARK_Mode is

   --  Box-drawing characters, by code point so that the source file
   --  stays plain ASCII.
   Horizontal   : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2500#);
   Vertical     : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2502#);
   Top_Left     : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#250C#);
   Top_Right    : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2510#);
   Bottom_Left  : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2514#);
   Bottom_Right : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2518#);

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Title : String := "";
      S     : Style  := Plain)
   is
   begin
      if Area.Extent.Width < 2 or else Area.Extent.Height < 2 then
         return;
      end if;

      declare
         Left   : constant Pixels := Area.Origin.X;
         Top    : constant Pixels := Area.Origin.Y;
         Right  : constant Pixels := Pixels (Thuja.Right (Area) - 1);
         Bottom : constant Pixels := Pixels (Thuja.Bottom (Area) - 1);
      begin
         Fill (Frame, Make (Left, Top, Area.Extent.Width, 1), (Horizontal, S));
         Fill (Frame, Make (Left, Bottom, Area.Extent.Width, 1), (Horizontal, S));
         Fill (Frame, Make (Left, Top, 1, Area.Extent.Height), (Vertical, S));
         Fill (Frame, Make (Right, Top, 1, Area.Extent.Height), (Vertical, S));

         Set (Frame, Left, Top, (Top_Left, S));
         Set (Frame, Right, Top, (Top_Right, S));
         Set (Frame, Left, Bottom, (Bottom_Left, S));
         Set (Frame, Right, Bottom, (Bottom_Right, S));

         --  The title sits on the top edge, with a space on each side,
         --  and is cut to the room there is between the corners.
         if Title'Length > 0 and then Area.Extent.Width > 6 then
            declare
               Room  : constant Positive := Natural (Area.Extent.Width) - 6;
               Shown : constant Positive := Positive'Min (Title'Length, Room);
               Last  : constant Positive := Title'First + (Shown - 1);
               Edge  : constant Rect := Make (Left + 1, Top, Area.Extent.Width - 2, 1);
            begin
               Put (Frame, Left + 2, Top, " ", S, Clip => Edge);
               Put (Frame, Left + 3, Top, Title (Title'First .. Last), S, Clip => Edge);
               Put (Frame, Left + 3 + Pixels (Shown), Top, " ", S, Clip => Edge);
            end;
         end if;
      end;
   end Draw;

end Thuja.Widgets.Blocks;
