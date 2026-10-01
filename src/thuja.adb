package body Thuja with SPARK_Mode is

   ------------------
   -- Intersection --
   ------------------

   function Intersection (A, B : Rect) return Rect is
      Left   : constant Pixels := Pixels'Max (A.Origin.X, B.Origin.X);
      Top    : constant Pixels := Pixels'Max (A.Origin.Y, B.Origin.Y);
      Right  : constant Integer := Integer'Min (Thuja.Right (A), Thuja.Right (B));
      Bottom : constant Integer := Integer'Min (Thuja.Bottom (A), Thuja.Bottom (B));
   begin
      if Right <= Integer (Left) or else Bottom <= Integer (Top) then
         return (Origin => (Left, Top), Extent => (0, 0));
      end if;

      return (Origin => (Left, Top),
              Extent => (Width  => Extent (Right - Integer (Left)),
                         Height => Extent (Bottom - Integer (Top))));
   end Intersection;

   -----------
   -- Inset --
   -----------

   function Inset (R : Rect; By : Extent) return Rect is
   begin
      if Integer (R.Extent.Width) <= 2 * Integer (By)
        or else Integer (R.Extent.Height) <= 2 * Integer (By)
      then
         return (Origin => R.Origin, Extent => (0, 0));
      end if;

      return (Origin => (R.Origin.X + By, R.Origin.Y + By),
              Extent => (Width  => R.Extent.Width - 2 * By,
                         Height => R.Extent.Height - 2 * By));
   end Inset;

end Thuja;
