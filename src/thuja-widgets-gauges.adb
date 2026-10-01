package body Thuja.Widgets.Gauges with SPARK_Mode is

   Full_Block  : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2588#);
   Light_Shade : constant Wide_Wide_Character := Wide_Wide_Character'Val (16#2591#);

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Value : Percent;
      S     : Style := Plain)
   is
      Filled : constant Extent := Extent (Natural (Area.Extent.Width) * Value / 100);
   begin
      if Is_Empty (Area) then
         return;
      end if;

      Fill (Frame, Make (Area.Origin.X, Area.Origin.Y, Area.Extent.Width, 1), (Light_Shade, S));
      Fill (Frame, Make (Area.Origin.X, Area.Origin.Y, Filled, 1), (Full_Block, S));
   end Draw;

end Thuja.Widgets.Gauges;
