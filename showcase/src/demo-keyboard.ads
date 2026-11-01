package Demo.Keyboard is
   type State is new Demo with record
      Last : Event := No_Event;
   end record;

   overriding procedure Draw   (D : in out State; Frame : in out Buffer; Area : Rect);
   overriding procedure Update (D : in out State; E : Event; Done : out Boolean);
end Demo.Keyboard;
