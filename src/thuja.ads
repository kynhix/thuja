--  thuja: a terminal user interface library.
--
--  Root package. Everything below shares these fundamental types.
--
--  The unit of everything is the CELL: one character position on the
--  terminal. Geometry comes from Bedrock.Screen (Point, Size, Rect), so
--  one "pixel" of Bedrock.Screen is one cell here, and the events of
--  Bedrock.Input (a resize, a mouse position) need no conversion.
--  X grows to the right, Y grows downward, (0, 0) is the top-left cell.

with Bedrock.Screen; use Bedrock.Screen;

package Thuja with SPARK_Mode, Pure is

   ---------------------------------------------------------------------
   --  Bounds
   ---------------------------------------------------------------------

   Max_Columns : constant := 400;
   Max_Rows    : constant := 150;
   --  Hard upper bounds on a frame. Bounded on purpose: no heap. A
   --  terminal larger than this is used up to these limits.

   subtype Column_Count is Extent range 0 .. Max_Columns;
   subtype Row_Count    is Extent range 0 .. Max_Rows;

   ---------------------------------------------------------------------
   --  Rectangles of cells
   ---------------------------------------------------------------------

   function Make (X, Y : Pixels; Width, Height : Extent) return Rect is
     ((Origin => (X, Y), Extent => (Width, Height)));

   function Is_Empty (R : Rect) return Boolean is
     (R.Extent.Width = 0 or else R.Extent.Height = 0);

   function Right (R : Rect) return Integer is
     (Integer (R.Origin.X) + Integer (R.Extent.Width));
   --  One past the last column of R.

   function Bottom (R : Rect) return Integer is
     (Integer (R.Origin.Y) + Integer (R.Extent.Height));
   --  One past the last row of R.

   function In_Range (R : Rect) return Boolean is
     (Right (R) <= Integer (Pixels'Last) and then Bottom (R) <= Integer (Pixels'Last));
   --  The far edges of R are coordinates too. Every rectangle thuja
   --  hands out is In_Range; only one built by hand at the far end of
   --  the coordinate space is not, and no terminal reaches there.

   function Inside (Inner, Outer : Rect) return Boolean is
     (Is_Empty (Inner)
      or else (Inner.Origin.X >= Outer.Origin.X
               and then Inner.Origin.Y >= Outer.Origin.Y
               and then Right (Inner) <= Right (Outer)
               and then Bottom (Inner) <= Bottom (Outer)));
   --  Every cell of Inner is a cell of Outer.

   function Intersection (A, B : Rect) return Rect
     with Post => Inside (Intersection'Result, A)
                  and then Inside (Intersection'Result, B)
                  and then (if In_Range (A) or else In_Range (B)
                            then In_Range (Intersection'Result));
   --  The cells that are in both. Empty when they do not meet.

   function Inset (R : Rect; By : Extent) return Rect
     with Pre  => In_Range (R),
          Post => Inside (Inset'Result, R) and then In_Range (Inset'Result);
   --  R shrunk by By cells on every side. Empty when R is too small.

end Thuja;
