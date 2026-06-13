import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import DiscourseRoute from "discourse/routes/discourse";

export default class UserInventoryRoute extends DiscourseRoute {
  @service router;

  model() {
    const user = this.modelFor("user");
    return ajax(`/leaderboard/user-inventory/${user.username}.json`)
      .then((response) => {
        return {
          user: user,
          items: response,
        };
      })
      .catch(() => this.router.replaceWith("/404"));
  }
}
