--  The component types of a thuja scene. See ../README.md.
--
--  Types only: no entity, no pool, no system. They compile on their
--  own so the design can be read and argued about before escape is
--  ready to store them.

with Bedrock.Names;
with Boxflex;
with Thuja.Styles;
with Thuja.Widgets.Gauges;
with Thuja.Widgets.Labels;

package Thuja_Scene is

   type Component_Kind is (Node, Frame, Text, Level, Focus);
   --  The formal of ECS.Worlds: one bit per kind in an entity's
   --  signature.

   type Node_Data is record
      Id : Boxflex.Node_Id := Boxflex.No_Node;
   end record;
   --  Where the entity is in the layout tree. Its rectangle is
   --  Thuja_Boxflex.Area (Tree, Id).

   type Frame_Data is record
      Title : Bedrock.Names.Name := Bedrock.Names.No_Name;
      Look  : Thuja.Styles.Style := Thuja.Styles.Plain;
   end record;

   type Text_Data is record
      Content : Bedrock.Names.Name             := Bedrock.Names.No_Name;
      Look    : Thuja.Styles.Style             := Thuja.Styles.Plain;
      Align   : Thuja.Widgets.Labels.Alignment := Thuja.Widgets.Labels.Left;
   end record;

   type Level_Data is record
      Value : Thuja.Widgets.Gauges.Percent := 0;
      Look  : Thuja.Styles.Style           := Thuja.Styles.Plain;
   end record;

   type Focus_Data is record
      Order   : Natural := 0;
      Focused : Boolean := False;
   end record;
   --  Order: position in the Tab cycle. Exactly one entity in a scene
   --  has Focused set.

end Thuja_Scene;
