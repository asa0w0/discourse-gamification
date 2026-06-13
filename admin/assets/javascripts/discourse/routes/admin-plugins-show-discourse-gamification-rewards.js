import DiscourseRoute from "discourse/routes/discourse";
import { ajax } from "discourse/lib/ajax";
import EmberObject from "@ember/object";

export default class DiscourseGamificationRewardsRoute extends DiscourseRoute {
  model() {
    if (!this.currentUser?.admin) {
      return { rewards: [], redemptions: [] };
    }

    return Promise.all([
      ajax("/admin/plugins/discourse-gamification/rewards.json"),
      ajax("/admin/plugins/discourse-gamification/redemptions.json")
    ]).then(([rewards, redemptions]) => {
      return EmberObject.create({
        rewards: rewards,
        redemptions: redemptions
      });
    });
  }
}
