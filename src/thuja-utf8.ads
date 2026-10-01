--  UTF-8 encoding of one character. Terminals speak UTF-8; cells hold
--  Wide_Wide_Character.

package Thuja.UTF8 with SPARK_Mode, Pure is

   function Encode (C : Wide_Wide_Character) return String
     with Post => Encode'Result'First = 1 and then Encode'Result'Length in 1 .. 4;
   --  The bytes of C. Code points that UTF-8 cannot carry (above
   --  16#10FFFF#, or the surrogate range) become '?'.

end Thuja.UTF8;
