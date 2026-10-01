--  One line of text in an area.

with Thuja.Buffers; use Thuja.Buffers;
with Thuja.Styles;  use Thuja.Styles;

package Thuja.Widgets.Labels with SPARK_Mode is

   type Alignment is (Left, Center, Right);

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Text  : String;
      S     : Style     := Plain;
      Align : Alignment := Left)
     with Pre => In_Range (Area);
   --  Text on the first row of Area. What does not fit is cut off.

end Thuja.Widgets.Labels;
