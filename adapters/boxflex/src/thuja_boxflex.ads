--  boxflex adapter: a boxflex layout tree, answered in cells.
--
--  boxflex lays out a tree of boxes with CSS-flexbox styles and gives
--  every node a rectangle, in fixed point. thuja draws into rectangles
--  of whole cells. This package is the conversion between the two:
--
--     one cell = 1.0 in boxflex coordinates
--
--  so a style says Cells (3) for "three rows high", and the rectangle
--  that comes back is rounded to whole cells.
--
--  With it, nested containers, wrapping, alignment and shrinking come
--  from boxflex, and every thuja widget draws into the rectangle of
--  its node:
--
--     Compute (Tree, Term.Size);
--     Blocks.Draw (Frame, Area (Tree, Sidebar), "Files");
--
--  It works exactly as far as the boxflex engine does. With the
--  boxflex seed (items packed in order, no grow, no stretch), boxes
--  get their fixed sizes and nothing else, which is not enough for a
--  screen yet: run layout_demo and compare with thuja's
--  showcase --snapshot.
--
--  NOT BUILT BY CI. It follows another team's crate.

with Bedrock.Screen;
with Boxflex;
with Boxflex.Geometry;
with Boxflex.Style;
with Boxflex.Tree; use Boxflex.Tree;

package Thuja_Boxflex is

   function Cells (N : Natural) return Boxflex.Style.Dimension
     with Pre => N <= 32_767;
   --  A fixed size of N cells, for Width, Height or Basis in a style.

   function To_Cells (R : Boxflex.Geometry.Rect) return Bedrock.Screen.Rect
     with Pre => Boxflex.Geometry.Edges_In_Range (R);
   --  R rounded to whole cells. Both edges are rounded, not the size,
   --  so two boxes that touch in boxflex still touch, with no gap and
   --  no overlap.

   procedure Compute (T : in out Layout_Tree; Screen : Bedrock.Screen.Size)
     with Pre  => Well_Formed (T) and then not Is_Empty (T),
          Post => Well_Formed (T);
   --  Lay the tree out in a terminal of this size. The root gets all
   --  of it.

   function Area (T : Layout_Tree; N : Boxflex.Node_Id) return Bedrock.Screen.Rect
     with Pre => Is_Valid (T, N);
   --  Where node N goes, in cells. Meaningful after Compute.

end Thuja_Boxflex;
