with Boxflex.Layout_Plain;

package body Thuja_Boxflex is

   use Bedrock.Screen;
   use type Boxflex.Coord;

   function Round (C : Boxflex.Coord) return Integer;
   --  The nearest whole cell, kept inside the range of Pixels.

   -----------
   -- Round --
   -----------

   function Round (C : Boxflex.Coord) return Integer is
     (if C <= Boxflex.Coord (Pixels'First) then Integer (Pixels'First)
      elsif C >= Boxflex.Coord (Pixels'Last) then Integer (Pixels'Last)
      else Integer (C));

   -----------
   -- Cells --
   -----------

   function Cells (N : Natural) return Boxflex.Style.Dimension is
     (Boxflex.Style.Px (Boxflex.Length (N)));

   --------------
   -- To_Cells --
   --------------

   function To_Cells (R : Boxflex.Geometry.Rect) return Bedrock.Screen.Rect is
      Left   : constant Integer := Round (R.Origin.X);
      Top    : constant Integer := Round (R.Origin.Y);
      Right  : constant Integer := Round (Boxflex.Geometry.Right (R));
      Bottom : constant Integer := Round (Boxflex.Geometry.Bottom (R));
   begin
      return (Origin => (Pixels (Left), Pixels (Top)),
              Extent => (Width  => Extent (Integer'Max (0, Right - Left)),
                         Height => Extent (Integer'Max (0, Bottom - Top))));
   end To_Cells;

   -------------
   -- Compute --
   -------------

   procedure Compute (T : in out Layout_Tree; Screen : Bedrock.Screen.Size) is
   begin
      Boxflex.Layout_Plain.Compute
        (T,
         Available => (Width  => Boxflex.Length (Screen.Width),
                       Height => Boxflex.Length (Screen.Height)));
   end Compute;

   ----------
   -- Area --
   ----------

   function Area (T : Layout_Tree; N : Boxflex.Node_Id) return Bedrock.Screen.Rect is
     (To_Cells (Layout_Of (T, N)));

end Thuja_Boxflex;
