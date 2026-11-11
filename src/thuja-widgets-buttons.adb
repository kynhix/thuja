with Thuja.Widgets.Labels;

use Thuja.Widgets.Labels;

package body Thuja.Widgets.Buttons is

   ------------
   -- Handle --
   ------------

   procedure Handle
     (S    : in out State;
      E    : Event;
      Used : out Boolean)
   is
   begin
      Used := False;

      if E.Kind = Key_Down then
         if E.Key = Key_Return then
            S.Activated := True;
            Used := True;
         end if;
      end if;
   end Handle;

   -----------------
   -- Was_Clicked --
   -----------------

   function Was_Clicked
     (S : in out State) return Boolean
   is
      Result : constant Boolean := S.Activated;
   begin
      S.Activated := False;
      return Result;
   end Was_Clicked;

   ----------
   -- Draw --
   ----------

   procedure Draw
     (Frame : in out Buffer;
      Area  : Rect;
      Text  : String)
   is
   begin
      if Is_Empty (Area) then
         return;
      end if;

      Labels.Draw
        (Frame => Frame,
         Area  => Area,
         Text  => "[ " & Text & " ]",
         Align => Thuja.Widgets.Labels.Center);

   end Draw;

end Thuja.Widgets.Buttons;