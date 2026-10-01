package body Thuja.Layout with SPARK_Mode is

   Max_Weight : constant := 1_000;
   --  Grow factors above this count as this: keeps the arithmetic far
   --  from overflow, and nobody needs a ratio finer than 1 to 1000.

   -----------
   -- Split --
   -----------

   function Split
     (Area  : Rect;
      Along : Direction;
      Items : Item_Array;
      Gap   : Extent := 0) return Rect_Array
   is
      Result : Rect_Array (Items'Range);

      Total : constant Natural :=
        Natural (if Along = Row then Area.Extent.Width else Area.Extent.Height);
      --  Cells available along the direction.

      Wanted : Natural := 0;   --  every basis, plus the gaps
      Shares : Natural := 0;   --  grow factors not yet served
      Spare  : Natural := 0;   --  cells not yet given to a grower
      Used   : Natural := 0;   --  cells handed out so far
      Size   : Natural;
      Weight : Natural;
      Extra  : Natural;
   begin
      for I in Items'Range loop
         Wanted := Wanted + Natural (Items (I).Basis) + Natural (Gap);
         Shares := Shares + Natural'Min (Items (I).Grow, Max_Weight);

         pragma Loop_Invariant (Wanted <= (I - Items'First + 1) * 2 * Natural (Extent'Last));
         pragma Loop_Invariant (Shares <= (I - Items'First + 1) * Max_Weight);
      end loop;

      --  One gap too many was counted: there is none before the first.
      if Wanted >= Natural (Gap) then
         Wanted := Wanted - Natural (Gap);
      end if;

      if Total > Wanted then
         Spare := Total - Wanted;
      end if;

      for I in Items'Range loop
         if I /= Items'First then
            Used := Natural'Min (Total, Used + Natural (Gap));
         end if;

         Size := Natural (Items (I).Basis);
         Weight := Natural'Min (Items (I).Grow, Max_Weight);

         --  Share what is left among the growers still to come, so that
         --  rounding never leaves a cell unused.
         if Weight > 0 and then Shares >= Weight then
            Extra := Natural'Min (Spare, Spare * Weight / Shares);
            Size := Size + Extra;
            Spare := Spare - Extra;
            Shares := Shares - Weight;
         end if;

         --  Never past the end of Area.
         Size := Natural'Min (Size, Total - Used);

         if Along = Row then
            Result (I) :=
              (Origin => (Area.Origin.X + Pixels (Used), Area.Origin.Y),
               Extent => (Extent (Size), Area.Extent.Height));
         else
            Result (I) :=
              (Origin => (Area.Origin.X, Area.Origin.Y + Pixels (Used)),
               Extent => (Area.Extent.Width, Extent (Size)));
         end if;

         Used := Used + Size;

         pragma Loop_Invariant (Used <= Total);
         pragma Loop_Invariant
           (for all J in Items'First .. I =>
              Inside (Result (J), Area) and then In_Range (Result (J)));
         pragma Loop_Invariant (Spare <= Total);
         pragma Loop_Invariant (Shares <= Items'Length * Max_Weight);
      end loop;

      return Result;
   end Split;

end Thuja.Layout;
