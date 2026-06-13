import RouteTemplate from "ember-route-template";
import AdminRewards from "../../../../admin/components/admin-rewards";

export default RouteTemplate(
  <template><AdminRewards @model={{@controller.model}} /></template>
);
