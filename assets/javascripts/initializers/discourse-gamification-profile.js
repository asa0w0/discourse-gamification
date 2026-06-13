import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-gamification-profile",

  initialize() {
    withPluginApi("1.1.0", (api) => {
      const siteSettings = api.container.lookup("service:site-settings");
      if (siteSettings.gamification_shop_enabled) {
        api.addProfileTab("inventory", {
          title: "gamification.inventory.title",
          route: "user.inventory",
          icon: "box-open",
        });
      }
    });
  },
};
