with Interfaces.C;

with Bedrock.Input; use Bedrock.Input;
with Thuja.Buffers; use Thuja.Buffers;
with Thuja.Generic_Renderer;
with Thuja.Input;

package body Thuja.Terminal is

   use type Interfaces.C.int;

   ---------------------------------------------------------------------
   --  The system side: src/<os>/thuja_term.c
   ---------------------------------------------------------------------

   function C_Open return Interfaces.C.int
     with Import, Convention => C, External_Name => "thuja_term_open";

   procedure C_Close
     with Import, Convention => C, External_Name => "thuja_term_close";

   function C_Size (Columns, Rows : access Interfaces.C.int) return Interfaces.C.int
     with Import, Convention => C, External_Name => "thuja_term_size";

   function C_Read
     (Buffer     : in out Interfaces.C.char_array;
      Max        : Interfaces.C.int;
      Timeout_Ms : Interfaces.C.int) return Interfaces.C.int
     with Import, Convention => C, External_Name => "thuja_term_read";

   function C_Write
     (Buffer : String;
      Length : Interfaces.C.int) return Interfaces.C.int
     with Import, Convention => C, External_Name => "thuja_term_write";

   ---------------------------------------------------------------------
   --  State. One terminal per process, so it lives here and not in the
   --  Session, which keeps Session small enough for any stack.
   ---------------------------------------------------------------------

   Escape_Wait : constant Duration := 0.05;
   --  How long a lone 1B waits for the rest of a sequence before it is
   --  taken to be the Escape key.

   Some_Session_Open : Boolean := False;

   On_Screen       : Buffer (Max_Columns, Max_Rows);
   On_Screen_Size  : Bedrock.Screen.Size := (0, 0);
   On_Screen_Valid : Boolean := False;
   --  What the terminal shows, as far as we know.

   Reported_Size : Bedrock.Screen.Size := (0, 0);
   --  The last size the application was told about.

   Decoder : Thuja.Input.Decoder;

   Incoming      : Interfaces.C.char_array (0 .. 255);
   Incoming_Next : Interfaces.C.size_t := 0;
   Incoming_Last : Interfaces.C.size_t := 0;
   --  Bytes read from the terminal and not yet decoded:
   --  Incoming (Incoming_Next .. Incoming_Last - 1).

   Outgoing      : String (1 .. 65_536);
   Outgoing_Last : Natural := 0;
   Sent          : Natural := 0;
   --  Bytes waiting to be written, and the count for the current frame.

   procedure Send;
   --  Write Outgoing to the terminal.

   procedure Queue (Bytes : String);
   --  Add to Outgoing, sending when it is full.

   package Renderer is new Thuja.Generic_Renderer (Emit => Queue);

   function Current_Size return Bedrock.Screen.Size;

   ----------
   -- Send --
   ----------

   procedure Send is
      Ignored : Interfaces.C.int;
   begin
      if Outgoing_Last > 0 then
         Ignored := C_Write (Outgoing, Interfaces.C.int (Outgoing_Last));
         Outgoing_Last := 0;
      end if;
   end Send;

   -----------
   -- Queue --
   -----------

   procedure Queue (Bytes : String) is
   begin
      if Bytes'Length > Outgoing'Length - Outgoing_Last then
         Send;
      end if;

      Outgoing (Outgoing_Last + 1 .. Outgoing_Last + Bytes'Length) := Bytes;
      Outgoing_Last := Outgoing_Last + Bytes'Length;
      Sent := Sent + Bytes'Length;
   end Queue;

   ------------------
   -- Current_Size --
   ------------------

   function Current_Size return Bedrock.Screen.Size is
      Columns : aliased Interfaces.C.int := 0;
      Rows    : aliased Interfaces.C.int := 0;
   begin
      if C_Size (Columns'Access, Rows'Access) /= 0 or else Columns < 1 or else Rows < 1 then
         return (80, 24);
      end if;

      return (Width  => Extent (Interfaces.C.int'Min (Columns, Max_Columns)),
              Height => Extent (Interfaces.C.int'Min (Rows, Max_Rows)));
   end Current_Size;

   ----------
   -- Open --
   ----------

   procedure Open (S : in out Session) is
   begin
      if Some_Session_Open then
         raise Program_Error with "a Thuja.Terminal.Session is already open";
      end if;

      if C_Open /= 0 then
         raise Not_A_Terminal with "standard input and output must be a terminal";
      end if;

      Some_Session_Open := True;
      S.Active := True;

      On_Screen_Valid := False;
      Reported_Size := Current_Size;
      Incoming_Next := 0;
      Incoming_Last := 0;
      Outgoing_Last := 0;
      Sent := 0;
   end Open;

   -----------
   -- Close --
   -----------

   procedure Close (S : in out Session) is
   begin
      if S.Active then
         Send;
         C_Close;
         S.Active := False;
         Some_Session_Open := False;
      end if;
   end Close;

   --------------
   -- Finalize --
   --------------

   overriding procedure Finalize (S : in out Session) is
   begin
      Close (S);
   end Finalize;

   ----------
   -- Size --
   ----------

   function Size (S : Session) return Bedrock.Screen.Size is
      pragma Unreferenced (S);
   begin
      return Current_Size;
   end Size;

   ----------
   -- Poll --
   ----------

   procedure Poll
     (S       : in out Session;
      Timeout : Duration;
      E       : out Bedrock.Input.Event)
   is
      pragma Unreferenced (S);
      use type Interfaces.C.size_t;

      Now   : constant Bedrock.Screen.Size := Current_Size;
      Wait  : Duration := Duration'Max (0.0, Timeout);
      Count : Interfaces.C.int;
   begin
      --  1. A resize comes first: the frame the application is about
      --     to draw depends on it.
      if Now /= Reported_Size then
         Reported_Size := Now;
         E := Resize_Event (Now.Width, Now.Height);
         return;
      end if;

      loop
         --  2. Decode what has already been read.
         while Incoming_Next < Incoming_Last loop
            Thuja.Input.Feed
              (Decoder, Interfaces.C.To_Ada (Incoming (Incoming_Next)), E);
            Incoming_Next := Incoming_Next + 1;

            if E.Kind /= None then
               return;
            end if;
         end loop;

         --  3. Read more. In the middle of a sequence, wait only a
         --     moment: if nothing follows, a lone 1B was the Escape key.
         if Thuja.Input.Pending (Decoder) then
            Wait := Duration'Min (Wait, Escape_Wait);
         end if;

         Count := C_Read
           (Incoming, Incoming'Length, Interfaces.C.int (Duration'Min (Wait, 3_600.0) * 1_000));

         if Count < 0 then
            E := Quit_Event;
            return;
         elsif Count = 0 then
            Thuja.Input.Flush (Decoder, E);
            return;
         end if;

         Incoming_Next := 0;
         Incoming_Last := Interfaces.C.size_t (Count);
      end loop;
   end Poll;

   -------------
   -- Present --
   -------------

   procedure Present (S : in out Session; Frame : Buffers.Buffer) is
      pragma Unreferenced (S);

      Frame_Size : constant Bedrock.Screen.Size := (Frame.Width, Frame.Height);
   begin
      Sent := 0;

      if On_Screen_Valid and then On_Screen_Size = Frame_Size then
         Renderer.Diff (Before => On_Screen, After => Frame);
      else
         Renderer.Full (Frame);
      end if;

      Send;

      Copy (Source => Frame, Target => On_Screen);
      On_Screen_Size := Frame_Size;
      On_Screen_Valid := True;
   end Present;

   ---------------------
   -- Bytes_Presented --
   ---------------------

   function Bytes_Presented (S : Session) return Natural is
      pragma Unreferenced (S);
   begin
      return Sent;
   end Bytes_Presented;

end Thuja.Terminal;
