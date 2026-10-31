--  The acceptance test, and the smallest complete thuja application.
--
--     showcase              run it in your terminal
--     showcase --snapshot   print one 80 x 24 frame as text and exit
--                           (no terminal needed: what CI runs)
--
--  Read this file first. It is the whole pattern on one page:
--
--     State   what the application knows                 (a record)
--     Draw    State -> a frame of cells                  (no I/O)
--     Update  State + one event -> State                 (no I/O)
--     the loop: Draw, Present, Poll, Update
--
--  Draw and Update never touch the terminal, which is why --snapshot
--  and the tests can run them anywhere.

with Ada.Command_Line;
with Ada.Text_IO;

with Bedrock.Colors;
with Bedrock.Input;  use Bedrock.Input;
with Bedrock.Screen; use Bedrock.Screen;

with Thuja;          use Thuja;
with Thuja.Buffers;  use Thuja.Buffers;
with Thuja.Layout;   use Thuja.Layout;
with Thuja.Styles;   use Thuja.Styles;
with Thuja.Terminal;
with Thuja.UTF8;
with Thuja.Widgets.Blocks;
with Thuja.Widgets.Gauges;
with Thuja.Widgets.Text_Fields;
with Thuja.Widgets.Labels;

procedure Showcase is

   package Blocks renames Thuja.Widgets.Blocks;
   package Gauges renames Thuja.Widgets.Gauges;
   package Labels renames Thuja.Widgets.Labels;

   package Text_Field renames Thuja.Widgets.Text_Fields;
   
   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   type App_State is record
      FirstNameDemo  : Text_Field.State;
      LastNameDemo  : Text_Field.State;
      Last_Event     : Event   := No_Event;
      Frames         : Natural := 0;
      Bytes          : Natural := 0;    
      --  sent to the terminal by the last frame
      Quit           : Boolean := False;
   end record;

   Accent : constant Style := Bold (Colored (Bedrock.Colors.Sky_Blue));
   Faint  : constant Style := Dim (Plain);

   function Image (N : Natural) return String;
   function Describe (Mods : Modifiers) return String;

   procedure Draw (Frame : in out Buffer; State : in out App_State);
   procedure Update (State : in out App_State; E : Event);
   procedure Print (Frame : Buffer);

   -----------
   -- Image --
   -----------

   function Image (N : Natural) return String is
      Text : constant String := N'Image;
   begin
      return Text (Text'First + 1 .. Text'Last);
   end Image;

   --------------
   -- Describe --
   --------------

   function Describe (Mods : Modifiers) return String is
     ((if Mods.Ctrl then "Ctrl " else "")
      & (if Mods.Alt then "Alt " else "")
      & (if Mods.Shift then "Shift " else "")
      & (if Mods = No_Modifiers then "none" else ""));

   ----------
   -- Draw --
   ----------

   procedure Draw (Frame : in out Buffer; State : in out App_State) is
      --  All placement comes from Split: three bands, the middle one
      --  takes what is left; the middle band is cut in two columns.
      Bands : constant Rect_Array :=
        Split (Area (Frame), Column, [Fixed (3), Flex, Fixed (3)]);
      Header : Rect renames Bands (1);
      Footer : Rect renames Bands (3);

      Panes : constant Rect_Array := Split (Bands (2), Row, [Fixed (50), Flex]);

      Info : constant Rect_Array :=
        Split (Blocks.Inner (Panes (2)), Column,
               [Fixed (1), Fixed (1), Fixed (1), Fixed (1), Fixed (1), Flex, Fixed (2)]);

      Status : constant Rect_Array :=
        Split (Blocks.Inner (Footer), Row, [Flex, Fixed (34)], Gap => 2);

      --  Set up two fields for the input boxes
      --  Each one is 3 units in height
      Fields : constant Rect_Array :=
        Split
         (Area  => Panes(1),
          Along => Column,
          Items => [Fixed (3), Fixed (3)],
          Gap   => 1);

      E : Event renames State.Last_Event;

   begin
      Blocks.Draw (Frame, Header, "thuja", Accent);
      Labels.Draw (Frame, Blocks.Inner (Header), "A terminal user interface library in Ada");
      Labels.Draw
        (Frame, Blocks.Inner (Header),
         Image (Natural (Frame.Width)) & " x " & Image (Natural (Frame.Height)),
         Faint, Labels.Right);

      --  Create the input boxes in the block.
      Blocks.Draw (Frame, Panes (1), "Text Inputs");
      Text_Field.Draw (Frame, Blocks.Inner (Fields (1)), State.FirstNameDemo, "First Name");
      Text_Field.Draw (Frame, Blocks.Inner (Fields (2)), State.LastNameDemo, "Last Name");

      Blocks.Draw (Frame, Panes (2), "Last event");
      Labels.Draw (Frame, Info (1), "kind : " & E.Kind'Image);

      case E.Kind is
         when Key_Down =>
            Labels.Draw (Frame, Info (2), "key  : " & E.Key'Image);
            Labels.Draw (Frame, Info (3), "mods : " & Describe (E.Mods));

         when Text_Input =>
            Labels.Draw (Frame, Info (2), "text : " & E.Text (1 .. E.Length));

         when Window_Resized =>
            Labels.Draw
              (Frame, Info (2),
               "size : " & Image (Natural (E.Size.Width)) & " x "
               & Image (Natural (E.Size.Height)));

         when others =>
            null;
      end case;

      Labels.Draw (Frame, Info (7), "Left/Right to move the cursor. Type to see keys decoded/appear.", Faint);
      Labels.Draw
        (Frame, Make (Info (7).Origin.X, Info (7).Origin.Y + 1, Info (7).Extent.Width, 1),
         "Try an accent, F5, Ctrl+Right: not decoded yet.", Faint);

      Blocks.Draw (Frame, Footer, "q quits");
      Gauges.Draw (Frame, Status (1), State.Frames mod 101, Accent);
      Labels.Draw
        (Frame, Status (2),
         "frame " & Image (State.Frames) & ", last sent " & Image (State.Bytes) & " bytes",
         Faint, Labels.Right);
   end Draw;

   ------------
   -- Update --
   ------------

   procedure Update (State : in out App_State; E : Event) is
      Used : Boolean;
   begin
      if E.Kind = None then
         return;
      end if;

      State.Last_Event := E;

      if E.Kind = Quit
        or else (E.Kind = Text_Input and then E.Text (1) = 'q')
        or else (E.Kind = Key_Down and then E.Key = Key_Escape)
        or else (E.Kind = Key_Down and then E.Key = Key_C and then E.Mods.Ctrl)
      then
         State.Quit := True;
         return;
      end if;

      --  Offer the event to the widgets that exist
      --  @TODO eventually replace with focus and event dispatcher
      Text_Field.Handle (State.FirstNameDemo, E, Used);
      Text_Field.Handle (State.LastNameDemo, E, Used);
   end Update;

   -----------
   -- Print --
   -----------

   procedure Print (Frame : Buffer) is
   begin
      for Y in 0 .. Frame.Height - 1 loop
         for C of Row_Image (Frame, Y) loop
            Ada.Text_IO.Put (Thuja.UTF8.Encode (C));
         end loop;

         Ada.Text_IO.New_Line;
      end loop;
   end Print;

   State : App_State;

begin
   if Ada.Command_Line.Argument_Count = 1
     and then Ada.Command_Line.Argument (1) = "--snapshot"
   then
      declare
         Frame : Buffer (80, 24);
      begin
         Update (State, Key_Event (Key_Down, Down => True));
         Update (State, Key_Event (Key_End, Down => True));
         Draw (Frame, State);
         Print (Frame);
      end;

      return;
   end if;

   declare
      Term : Thuja.Terminal.Session;
      E    : Event;
   begin
      Term.Open;

      --  This will intialie the Text Field outside of the drawing loop
      Text_Field.Set_Text(State.LastNameDemo, "Bluey");

      while not State.Quit loop
         declare
            Now   : constant Size := Term.Size;
            Frame : Buffer (Now.Width, Now.Height);
         begin
            
            Draw (Frame, State);
            Term.Present (Frame);
         end;

         State.Frames := State.Frames + 1;
         State.Bytes := Term.Bytes_Presented;

         Term.Poll (Timeout => 0.1, E => E);
         Update (State, E);
      end loop;

      Term.Close;
   end;

exception
   when Thuja.Terminal.Not_A_Terminal =>
      Ada.Text_IO.Put_Line ("showcase needs an interactive terminal.");
      Ada.Text_IO.Put_Line ("Without one, try: showcase --snapshot");
      Ada.Command_Line.Set_Exit_Status (1);
end Showcase;
