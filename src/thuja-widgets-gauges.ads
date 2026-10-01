--  A horizontal progress bar. The first cohort's Progress Bar widget.

with Thuja.Buffers; use Thuja.Buffers;
with Thuja.Styles;  use Thuja.Styles;

package Thuja.Widgets.Gauges with SPARK_Mode is

   subtype Percent is Natural range 0 .. 100;

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Value : Percent;
      S     : Style := Plain)
     with Pre => In_Range (Area);
   --  The first row of Area, filled from the left in proportion to
   --  Value.

end Thuja.Widgets.Gauges;
