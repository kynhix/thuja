package body Thuja.UTF8 with SPARK_Mode is

   ------------
   -- Encode --
   ------------

   function Encode (C : Wide_Wide_Character) return String is
      Code : constant Natural := Wide_Wide_Character'Pos (C);

      function Tail (Divisor : Positive) return Character is
        (Character'Val (16#80# + (Code / Divisor) mod 64));
      --  A continuation byte: 10xxxxxx, six bits of Code.
   begin
      if Code < 16#80# then
         return [1 => Character'Val (Code)];
      elsif Code < 16#800# then
         return [Character'Val (16#C0# + Code / 64), Tail (1)];
      elsif Code in 16#D800# .. 16#DFFF# or else Code > 16#10_FFFF# then
         return "?";
      elsif Code < 16#1_0000# then
         return [Character'Val (16#E0# + Code / 4096), Tail (64), Tail (1)];
      else
         return [Character'Val (16#F0# + Code / 262_144), Tail (4096), Tail (64), Tail (1)];
      end if;
   end Encode;

end Thuja.UTF8;
