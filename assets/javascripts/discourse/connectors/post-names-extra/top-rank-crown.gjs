import Component from "@glimmer/component";
import icon from "discourse/helpers/d-icon";

export default class TopRankCrown extends Component {
  get position() {
    return this.args.outletArgs?.post?.user?.gamification_position;
  }

  get crownClass() {
    return `-position${this.position}`;
  }

  get crownTitle() {
    return `Rang ${this.position} Bestenliste`;
  }

  <template>
    {{#if this.position}}
      <span class="gamification-top-rank-crown {{this.crownClass}}" title={{this.crownTitle}}>
        {{icon "crown"}}
      </span>
    {{/if}}
  </template>
}
