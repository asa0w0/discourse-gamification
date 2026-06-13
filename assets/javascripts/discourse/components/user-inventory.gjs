import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq, or } from "truth-helpers";
import { fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class UserInventory extends Component {
  @service currentUser;

  @tracked items = this.args.model.items;
  @tracked equipping = {};

  get isCurrentUser() {
    return this.currentUser && this.currentUser.username === this.args.model.user.username;
  }

  @action
  toggleEquip(item) {
    if (this.equipping[item.id]) {
      return;
    }
    this.equipping = { ...this.equipping, [item.id]: true };

    ajax(`/leaderboard/shop/inventory/${item.id}/toggle_equip`, {
      type: "POST",
    })
      .then((updatedItem) => {
        // Update items list
        this.items = this.items.map((invItem) => {
          if (invItem.reward.reward_type === updatedItem.reward.reward_type) {
            invItem.equipped = false;
          }
          if (invItem.id === updatedItem.id) {
            return updatedItem;
          }
          return invItem;
        });
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.equipping = { ...this.equipping, [item.id]: false };
      });
  }

  <template>
    <div class="user-inventory-showcase">
      {{#if this.items.length}}
        <div class="inventory-grid">
          {{#each this.items as |item|}}
            <div class="inventory-item-card {{if item.equipped 'equipped'}}">
              <div class="inventory-item-icon-wrapper">
                {{icon item.reward.icon}}
                {{#if item.equipped}}
                  <span class="equipped-badge">{{icon "check"}}</span>
                {{/if}}
              </div>
              <h3 class="inventory-item-name">{{item.reward.name}}</h3>
              <p class="inventory-item-description">{{item.reward.description}}</p>

              <div class="inventory-item-footer">
                <span class="inventory-item-status status-{{item.status}}">
                  {{i18n (concat "gamification.shop.status_" item.status)}}
                </span>

                {{#if this.isCurrentUser}}
                  {{#if (or (eq item.reward.reward_type "title") (eq item.reward.reward_type "avatar_frame"))}}
                    <DButton
                      @action={{fn this.toggleEquip item}}
                      @disabled={{get this.equipping item.id}}
                      class={{if item.equipped "btn-danger" "btn-primary"}}
                      @label={{if item.equipped "gamification.inventory.unequip" "gamification.inventory.equip"}}
                    />
                  {{/if}}
                {{/if}}
              </div>
            </div>
          {{/each}}
        </div>
      {{else}}
        <div class="empty-inventory">
          {{icon "box-open"}}
          <p>{{i18n "gamification.inventory.empty_inventory"}}</p>
        </div>
      {{/if}}
    </div>
  </template>
}
