with Bedrock.Input;  use Bedrock.Input;
with Bedrock.Screen; use Bedrock.Screen;
with Thuja.Buffers;  use Thuja.Buffers;

package Demo is
   type Demo is interface;

   procedure Draw   (D : in out Demo; Frame : in out Buffer; Area : Rect) is abstract;
   procedure Update (D : in out Demo; E : Event; Done : out Boolean) is abstract;
end Demos;
