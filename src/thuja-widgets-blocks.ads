--  A border around an area, with an optional title on its top edge.
--  The container of the other widgets: draw the block, then draw
--  inside Inner (Area).

with Thuja.Buffers; use Thuja.Buffers;
with Thuja.Styles;  use Thuja.Styles;

package Thuja.Widgets.Blocks with SPARK_Mode is

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Title : String := "";
      S     : Style  := Plain)
     with Pre => In_Range (Area);
   --  Nothing is drawn if Area is less than 2 x 2.

   function Inner (Area : Rect) return Rect is (Inset (Area, 1))
     with Pre  => In_Range (Area),
          Post => In_Range (Inner'Result) and then Inside (Inner'Result, Area);
   --  What is left inside the border.

end Thuja.Widgets.Blocks;
