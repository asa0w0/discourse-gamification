import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { LinkTo } from "@ember/routing";
import { eq, or } from "truth-helpers";
import { hash, fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import number from "discourse/helpers/number";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";
import fullnumber from "../helpers/fullnumber";

export default class GamificationShop extends Component {
  @service dialog;
  @service router;

  @tracked activeTab = "catalog"; // "catalog" or "inventory"
  @tracked balance = this.args.model.balance;
  @tracked inventory = this.args.model.inventory;
  @tracked buying = false;
  @tracked equipping = {};

  get rewards() {
    return this.args.model.rewards;
  }

  get isBalanceLessThanCost() {
    return (rewardCost) => this.balance < rewardCost;
  }

  @action
  setTab(tab) {
    this.activeTab = tab;
  }

  @action
  confirmBuy(reward) {
    this.dialog.confirm({
      message: i18n("gamification.shop.redeem_confirm", {
        name: reward.name,
        cost: reward.cost,
      }),
      didConfirm: () => this.buyItem(reward),
    });
  }

  buyItem(reward) {
    if (this.buying) {
      return;
    }
    this.buying = true;

    ajax("/leaderboard/shop/buy", {
      type: "POST",
      data: { reward_id: reward.id },
    })
      .then((newItem) => {
        this.balance -= reward.cost;
        this.inventory = [newItem, ...this.inventory];
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.buying = false;
      });
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
        // Update item in inventory list
        this.inventory = this.inventory.map((invItem) => {
          // If we equipped a title/frame, other items of the same type get unequipped automatically
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
    <div class="leaderboard gamification-shop-container">
      <div class="page__header">
        <h1 class="page__title">{{i18n "gamification.shop.title"}}</h1>
      </div>

      <div class="gamification-navigation-tabs">
        <LinkTo @route="gamificationLeaderboard.index" class="gamification-tab-link">
          {{icon "award"}} {{i18n "gamification.leaderboard.title"}}
        </LinkTo>
        <LinkTo @route="gamificationLeaderboard.shop" class="gamification-tab-link active">
          {{icon "gift"}} {{i18n "gamification.shop.title"}}
        </LinkTo>
      </div>

      <div class="shop-dashboard-card">
        <div class="shop-balance-info">
          <span class="balance-label">{{i18n "gamification.shop.balance" balance=(fullnumber this.balance)}}</span>
        </div>
        <div class="shop-sub-tabs">
          <button
            class="shop-sub-tab {{if (eq this.activeTab 'catalog') 'active'}}"
            type="button"
            {{on "click" (fn this.setTab "catalog")}}
          >
            {{icon "store"}} {{i18n "gamification.shop.title"}}
          </button>
          <button
            class="shop-sub-tab {{if (eq this.activeTab 'inventory') 'active'}}"
            type="button"
            {{on "click" (fn this.setTab "inventory")}}
          >
            {{icon "box-open"}} {{i18n "gamification.inventory.title"}}
          </button>
        </div>
      </div>

      {{#if (eq this.activeTab "catalog")}}
        <div class="shop-grid">
          {{#each this.rewards as |reward|}}
            <div class="shop-item-card">
              <div class="shop-item-icon-wrapper">
                {{icon reward.icon}}
              </div>
              <h3 class="shop-item-name">{{reward.name}}</h3>
              <p class="shop-item-description">{{reward.description}}</p>
              <div class="shop-item-footer">
                <span class="shop-item-cost">
                  {{icon "award"}} {{fullnumber reward.cost}}
                </span>
                <DButton
                  @action={{fn this.confirmBuy reward}}
                  @disabled={{or this.buying (this.isBalanceLessThanCost reward.cost)}}
                  class="btn-primary buy-button"
                  @label="gamification.shop.redeem"
                />
              </div>
            </div>
          {{/each}}
        </div>
      {{else}}
        <div class="inventory-list">
          {{#if this.inventory.length}}
            <div class="inventory-grid">
              {{#each this.inventory as |item|}}
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

                    {{#if (or (eq item.reward.reward_type "title") (eq item.reward.reward_type "avatar_frame"))}}
                      <DButton
                        @action={{fn this.toggleEquip item}}
                        @disabled={{get this.equipping item.id}}
                        class={{if item.equipped "btn-danger" "btn-primary"}}
                        @label={{if item.equipped "gamification.inventory.unequip" "gamification.inventory.equip"}}
                      />
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
      {{/if}}
    </div>
  </template>
}
