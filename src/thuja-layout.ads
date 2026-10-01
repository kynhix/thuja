--  Cutting a rectangle into smaller ones. The only place where cell
--  arithmetic for layout is allowed: widgets and applications say what
--  they want (three rows, the middle one takes what is left) and get
--  rectangles back.
--
--  The vocabulary is flexbox's, and Boxflex.Flex's: a container with a
--  direction and a gap, items with a basis and a grow factor. That is
--  deliberate. Split is the seam where thuja meets the layout engine:
--
--    today     the body below, a small integer algorithm (the fallback)
--    later     the same spec, its body a call to Boxflex.Flex.Resolve
--
--  so that nested and wrapped layouts, alignment and shrinking come from
--  boxflex and are not written twice.
--
--  What Split guarantees, whatever the inputs: one rectangle per item,
--  in order, each inside Area, none overlapping another. When Area is
--  too small the last items become empty; nothing is ever drawn outside.

package Thuja.Layout with SPARK_Mode is

   type Direction is (Row, Column);
   --  Row lays items left to right; Column, top to bottom.

   type Item is record
      Basis : Extent  := 0;
      Grow  : Natural := 0;
   end record;
   --  Basis: the cells the item asks for along the direction.
   --  Grow : its share of the cells left once every basis is served.
   --         0 means "exactly my basis".

   function Fixed (Cells : Extent) return Item is ((Basis => Cells, Grow => 0));
   function Flex (Weight : Positive := 1) return Item is ((Basis => 0, Grow => Weight));

   Max_Items : constant := 64;
   subtype Item_Index is Positive range 1 .. Max_Items;

   type Item_Array is array (Item_Index range <>) of Item;
   type Rect_Array is array (Item_Index range <>) of Rect;

   function Split
     (Area  : Rect;
      Along : Direction;
      Items : Item_Array;
      Gap   : Extent := 0) return Rect_Array
     with Pre  => In_Range (Area),
          Post => Split'Result'First = Items'First
                  and then Split'Result'Last = Items'Last
                  and then (for all R of Split'Result =>
                              Inside (R, Area) and then In_Range (R));
   --  Proved: no run-time error, and the postcondition, for every input.

end Thuja.Layout;
