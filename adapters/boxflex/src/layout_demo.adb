--  The same screen as thuja's showcase, laid out by boxflex instead of
--  Thuja.Layout.Split, printed as text.
--
--  THE ACCEPTANCE TEST OF THE GLUE: when this prints the same boxes as
--  `showcase --snapshot`, boxflex can lay out a thuja application.
--  With the boxflex seed engine nothing stretches or grows, so every
--  box is zero cells wide and the frame is blank: the rectangles
--  printed above it show how far the engine got.
--
--     root (column)
--     +-- header   height 3
--     +-- body     grow 1, row
--     |   +-- list     width 24
--     |   +-- detail   grow 1
--     +-- footer   height 3

with Ada.Text_IO;

with Bedrock.Screen; use Bedrock.Screen;

with Boxflex;
with Boxflex.Style;  use Boxflex.Style;
with Boxflex.Tree;   use Boxflex.Tree;

with Thuja.Buffers;  use Thuja.Buffers;
with Thuja.UTF8;
with Thuja.Widgets.Blocks;
with Thuja_Boxflex;  use Thuja_Boxflex;

procedure Layout_Demo is

   Tree : Layout_Tree;
   Root, Header, Content, List, Detail, Footer : Boxflex.Node_Id;

   Frame : Buffer (80, 24);

   --  Draw the node as a titled box, and say where boxflex put it.
   procedure Box (Node : Boxflex.Node_Id; Title : String) is
      Where : constant Rect := Area (Tree, Node);
   begin
      Thuja.Widgets.Blocks.Draw (Frame, Where, Title);
      Ada.Text_IO.Put_Line
        (Title & ": column" & Where.Origin.X'Image & ", row" & Where.Origin.Y'Image
         & "," & Where.Extent.Width'Image & " x" & Where.Extent.Height'Image);
   end Box;

begin
   Clear (Tree);

   Insert (Tree, Boxflex.No_Node, (Default_Style with delta Direction => Column), Root);
   Insert (Tree, Root, (Default_Style with delta Height => Cells (3)), Header);
   Insert (Tree, Root, (Default_Style with delta Grow => 1.0, Direction => Row), Content);
   Insert (Tree, Content, (Default_Style with delta Width => Cells (24)), List);
   Insert (Tree, Content, (Default_Style with delta Grow => 1.0), Detail);
   Insert (Tree, Root, (Default_Style with delta Height => Cells (3)), Footer);

   Compute (Tree, (Width => Frame.Width, Height => Frame.Height));

   Box (Header, "thuja");
   Box (List, "Demos to rebuild");
   Box (Detail, "Last event");
   Box (Footer, "q quits");

   for Y in 0 .. Frame.Height - 1 loop
      for C of Row_Image (Frame, Y) loop
         Ada.Text_IO.Put (Thuja.UTF8.Encode (C));
      end loop;

      Ada.Text_IO.New_Line;
   end loop;
end Layout_Demo;
