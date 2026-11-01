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

with Thuja;         use Thuja;
with Thuja.Buffers; use Thuja.Buffers;
with Thuja.Layout;  use Thuja.Layout;
with Thuja.Styles;  use Thuja.Styles;
with Thuja.Terminal;
with Thuja.UTF8;
with Thuja.Widgets.Blocks;
with Thuja.Widgets.Gauges;
with Thuja.Widgets.Generic_Lists;
with Thuja.Widgets.Labels;

procedure Showcase is

   package Blocks renames Thuja.Widgets.Blocks;
   package Gauges renames Thuja.Widgets.Gauges;
   package Labels renames Thuja.Widgets.Labels;

   ---------------------------------------------------------------------
   --  The rows of the list: the demos of the first thuja, the ones to
   --  rebuild on this core.
   ---------------------------------------------------------------------

   function Demo_Count return Natural
   is (6);

   function Demo_Name (Index : Positive) return String
   is (case Index is
         when 1      => "HTop",
         when 2      => "Text Editor",
         when 3      => "Flexbox",
         when 4      => "Sort Visual",
         when 5      => "Sine Wave",
         when others => "Keyboard");

   package Demo_Lists is new
     Thuja.Widgets.Generic_Lists (Count => Demo_Count, Text => Demo_Name);

   ---------------------------------------------------------------------
   --  State
   ---------------------------------------------------------------------

   type Focus_Target is (Left_List, Right_List);

   type App_State is record
      Focus       : Focus_Target := Left_List;
      Left_Demos  : Demo_Lists.State;
      Right_Demos : Demo_Lists.State;
      Last_Event  : Event := No_Event;
      Frames      : Natural := 0;
      Bytes       : Natural := 0; -- sent to terminal by the last frame
      Quit        : Boolean := False;
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

   function Describe (Mods : Modifiers) return String
   is ((if Mods.Ctrl then "Ctrl " else "")
       & (if Mods.Alt then "Alt " else "")
       & (if Mods.Shift then "Shift " else "")
       & (if Mods = No_Modifiers then "none" else ""));
   pragma Warnings (Off, Describe);

   ----------
   -- Draw --
   ----------

   procedure Draw (Frame : in out Buffer; State : in out App_State) is
      Bands  : constant Rect_Array :=
        Split (Area (Frame), Column, [Fixed (3), Flex, Fixed (3)]);
      Header : Rect renames Bands (1);
      Footer : Rect renames Bands (3);

      --  Split the terminal content grid in half (left and right columns)
      Panes : constant Rect_Array := Split (Bands (2), Row, [Flex, Flex]);

      Status : constant Rect_Array :=
        Split (Blocks.Inner (Footer), Row, [Flex, Fixed (34)], Gap => 2);

      Left_Active  : constant Boolean := State.Focus = Left_List;
      Right_Active : constant Boolean := State.Focus = Right_List;
   begin
      Blocks.Draw (Frame, Header, "thuja", Accent);
      Labels.Draw
        (Frame,
         Blocks.Inner (Header),
         "A terminal user interface library in Ada");
      Labels.Draw
        (Frame,
         Blocks.Inner (Header),
         Image (Natural (Frame.Width))
         & " x "
         & Image (Natural (Frame.Height)),
         Faint,
         Labels.Right);

      --  Left List Widget
      Blocks.Draw
        (Frame,
         Panes (1),
         Title => (if Left_Active then "Demos (Active)" else "Demos"),
         S     => (if Left_Active then Accent else Faint));
      Demo_Lists.Draw
        (Frame,
         Blocks.Inner (Panes (1)),
         State.Left_Demos,
         Highlight => (if Left_Active then Inverse (Plain) else Faint));

      --  Right List Widget
      Blocks.Draw
        (Frame,
         Panes (2),
         Title =>
           (if Right_Active then "Second List (Active)" else "Second List"),
         S     => (if Right_Active then Accent else Faint));
      Demo_Lists.Draw
        (Frame,
         Blocks.Inner (Panes (2)),
         State.Right_Demos,
         Highlight => (if Right_Active then Inverse (Plain) else Faint));

      Blocks.Draw (Frame, Footer, "q quits | Tab switches focus");
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

      --  Tab toggles focus between left and right lists
      if E.Kind = Key_Down and then E.Key = Key_Tab then
         State.Focus :=
           (if State.Focus = Left_List then Right_List else Left_List);
         return;
      end if;

      --  Route input only to the currently focused list widget
      case State.Focus is
         when Left_List  =>
            Demo_Lists.Handle (State.Left_Demos, E, Used);

         when Right_List =>
            Demo_Lists.Handle (State.Right_Demos, E, Used);
      end case;
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
