package body Thuja.Widgets.Labels with SPARK_Mode is

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Text  : String;
      S     : Style     := Plain;
      Align : Alignment := Left)
   is
      Room  : constant Natural := Natural (Area.Extent.Width);
      Shown : constant Natural := Natural'Min (Text'Length, Room);
      Skip  : constant Natural :=
        (case Align is
            when Left   => 0,
            when Center => (Room - Shown) / 2,
            when Right  => Room - Shown);
   begin
      if Is_Empty (Area) then
         return;
      end if;

      Put (Frame, Area.Origin.X + Pixels (Skip), Area.Origin.Y, Text, S, Clip => Area);
   end Draw;

end Thuja.Widgets.Labels;
