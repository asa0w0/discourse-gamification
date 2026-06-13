import RouteTemplate from "ember-route-template";
import UserInventory from "../components/user-inventory";

export default RouteTemplate(
  <template><UserInventory @model={{@controller.model}} /></template>
);
