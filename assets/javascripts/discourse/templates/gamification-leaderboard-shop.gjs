import RouteTemplate from "ember-route-template";
import GamificationShop from "../components/gamification-shop";

export default RouteTemplate(
  <template><GamificationShop @model={{@controller.model}} /></template>
);
