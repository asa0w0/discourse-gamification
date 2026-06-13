import Component from "@ember/component";
import { tagName } from "@ember-decorators/component";
import { or } from "truth-helpers";
import avatar from "discourse/helpers/avatar";
import number from "discourse/helpers/number";
import fullnumber from "../helpers/fullnumber";

@tagName("")
export default class GamificationLeaderboardRow extends Component {
  rank = null;

  get positionChange() {
    return this.rank.position_change || 0;
  }

  get rankChangeClass() {
    const change = this.positionChange;
    if (change > 0) {
      return "up";
    } else if (change < 0) {
      return "down";
    }
    return "no-change";
  }

  get rankChangeSymbol() {
    const change = this.positionChange;
    if (change > 0) {
      return "▲";
    } else if (change < 0) {
      return "▼";
    }
    return "";
  }

  get absRankChange() {
    return Math.abs(this.positionChange);
  }

  <template>
    <div
      class="user {{if this.rank.currentUser 'user-highlight'}}"
      id="leaderboard-user-{{this.rank.id}}"
    >
      <div class="user__rank">
        <span class="user__position">{{this.rank.position}}</span>
        {{#if this.positionChange}}
          <span class="user__rank-change {{this.rankChangeClass}}" title="Rangänderung im Vergleich zum Vortag">
            {{this.rankChangeSymbol}}{{this.absRankChange}}
          </span>
        {{/if}}
      </div>
      <div
        class="user__avatar clickable"
        role="button"
        data-user-card={{this.rank.username}}
      >
        {{avatar this.rank imageSize="large"}}
        <span class="user__name">
          {{#if this.siteSettings.prioritize_username_in_ux}}
            {{this.rank.username}}
          {{else}}
            {{or this.rank.name this.rank.username}}
          {{/if}}
        </span>
      </div>
      <div class="user__score">
        {{#if this.site.mobileView}}
          {{number this.rank.total_score}}
        {{else}}
          {{fullnumber this.rank.total_score}}
        {{/if}}
      </div>
    </div>
  </template>
}
