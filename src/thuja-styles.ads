--  How a cell looks: two colours and a few attributes.
--
--  Colours are Bedrock.Colors.Color. A colour with alpha 0 means "the
--  terminal's own colour": the user's theme decides. Any other alpha is
--  an exact RGB colour.

with Bedrock.Colors; use Bedrock.Colors;

package Thuja.Styles with SPARK_Mode, Pure is

   Default_Color : Color renames Transparent;

   function Is_Default (C : Color) return Boolean is (C.A = 0);

   type Attributes is record
      Bold          : Boolean := False;
      Dim           : Boolean := False;
      Italic        : Boolean := False;
      Underline     : Boolean := False;
      Strikethrough : Boolean := False;
      Inverse       : Boolean := False;
   end record;

   No_Attributes : constant Attributes := (False, False, False, False, False, False);

   type Style is record
      Foreground : Color      := Default_Color;
      Background : Color      := Default_Color;
      Attr       : Attributes := No_Attributes;
   end record;

   Plain : constant Style :=
     ((0, 0, 0, 0), (0, 0, 0, 0), (False, False, False, False, False, False));

   function Colored (Foreground : Color; Background : Color := Default_Color) return Style is
     ((Foreground, Background, No_Attributes));

   function Bold (S : Style) return Style is
     ((S.Foreground, S.Background, (S.Attr with delta Bold => True)));

   function Dim (S : Style) return Style is
     ((S.Foreground, S.Background, (S.Attr with delta Dim => True)));

   function Inverse (S : Style) return Style is
     ((S.Foreground, S.Background, (S.Attr with delta Inverse => True)));

end Thuja.Styles;
