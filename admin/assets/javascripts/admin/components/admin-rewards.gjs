import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { on } from "@ember/modifier";
import { eq, or } from "truth-helpers";
import { hash, fn } from "@ember/helper";
import DButton from "discourse/components/d-button";
import icon from "discourse/helpers/d-icon";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { i18n } from "discourse-i18n";

export default class AdminRewards extends Component {
  @tracked activeTab = "items"; // "items" or "redemptions"
  @tracked rewards = this.args.model.rewards;
  @tracked redemptions = this.args.model.redemptions;

  // Form states
  @tracked editingReward = null;
  @tracked isCreating = false;
  @tracked name = "";
  @tracked description = "";
  @tracked cost = 100;
  @tracked rewardType = "manual";
  @tracked rewardValue = "";
  @tracked iconName = "gift";

  @tracked saving = false;
  @tracked processingRedemption = {};

  @action
  setTab(tab) {
    this.activeTab = tab;
  }

  @action
  startCreate() {
    this.isCreating = true;
    this.editingReward = null;
    this.name = "";
    this.description = "";
    this.cost = 100;
    this.rewardType = "manual";
    this.rewardValue = "";
    this.iconName = "gift";
  }

  @action
  cancelEdit() {
    this.isCreating = false;
    this.editingReward = null;
  }

  @action
  startEdit(reward) {
    this.isCreating = false;
    this.editingReward = reward;
    this.name = reward.name;
    this.description = reward.description;
    this.cost = reward.cost;
    this.rewardType = reward.reward_type;
    this.rewardValue = reward.reward_value;
    this.iconName = reward.icon;
  }

  @action
  saveReward(e) {
    e.preventDefault();
    if (this.saving) {
      return;
    }
    this.saving = true;

    const data = {
      name: this.name,
      description: this.description,
      cost: this.cost,
      reward_type: this.rewardType,
      reward_value: this.rewardValue,
      icon: this.iconName,
    };

    let promise;
    if (this.editingReward) {
      promise = ajax(`/admin/plugins/discourse-gamification/rewards/${this.editingReward.id}`, {
        type: "PUT",
        data: data,
      });
    } else {
      promise = ajax("/admin/plugins/discourse-gamification/rewards", {
        type: "POST",
        data: data,
      });
    }

    promise
      .then((savedReward) => {
        if (this.editingReward) {
          this.rewards = this.rewards.map((r) => (r.id === savedReward.id ? savedReward : r));
        } else {
          this.rewards = [...this.rewards, savedReward];
        }
        this.cancelEdit();
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.saving = false;
      });
  }

  @action
  deleteReward(reward) {
    if (!confirm(i18n("gamification.leaderboard.confirm_destroy"))) {
      return;
    }

    ajax(`/admin/plugins/discourse-gamification/rewards/${reward.id}`, {
      type: "DELETE",
    })
      .then(() => {
        this.rewards = this.rewards.filter((r) => r.id !== reward.id);
      })
      .catch(popupAjaxError);
  }

  @action
  approveRedemption(redemption) {
    if (this.processingRedemption[redemption.id]) {
      return;
    }
    this.processingRedemption = { ...this.processingRedemption, [redemption.id]: true };

    ajax(`/admin/plugins/discourse-gamification/redemptions/${redemption.id}/approve`, {
      type: "POST",
    })
      .then((updatedRedemption) => {
        this.redemptions = this.redemptions.map((r) =>
          r.id === updatedRedemption.id ? { ...r, status: "delivered" } : r
        );
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.processingRedemption = { ...this.processingRedemption, [redemption.id]: false };
      });
  }

  @action
  rejectRedemption(redemption) {
    if (this.processingRedemption[redemption.id]) {
      return;
    }
    if (!confirm("Are you sure you want to reject and refund this order?")) {
      return;
    }
    this.processingRedemption = { ...this.processingRedemption, [redemption.id]: true };

    ajax(`/admin/plugins/discourse-gamification/redemptions/${redemption.id}/reject`, {
      type: "POST",
    })
      .then((updatedRedemption) => {
        this.redemptions = this.redemptions.map((r) =>
          r.id === updatedRedemption.id ? { ...r, status: "rejected" } : r
        );
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.processingRedemption = { ...this.processingRedemption, [redemption.id]: false };
      });
  }

  <template>
    <div class="admin-rewards-container">
      <h2>{{i18n "gamification.admin.title"}} - {{i18n "gamification.shop.title"}}</h2>

      <div class="admin-tabs">
        <button
          class="admin-tab-btn {{if (eq this.activeTab 'items') 'active'}}"
          type="button"
          {{on "click" (fn this.setTab "items")}}
        >
          {{icon "store"}} Shop-Items
        </button>
        <button
          class="admin-tab-btn {{if (eq this.activeTab 'redemptions') 'active'}}"
          type="button"
          {{on "click" (fn this.setTab "redemptions")}}
        >
          {{icon "list"}} Bestellungen / Einlösungen
        </button>
      </div>

      {{#if (eq this.activeTab "items")}}
        <div class="admin-items-view">
          {{#if (or this.isCreating this.editingReward)}}
            <form {{on "submit" this.saveReward}} class="admin-reward-form form-vertical">
              <div class="control-group">
                <label>Item-Name</label>
                <input type="text" class="input-large" required {{on "input" (action (mut this.name) value="target.value")}} value={{this.name}} />
              </div>
              <div class="control-group">
                <label>Beschreibung</label>
                <textarea class="input-large" {{on "input" (action (mut this.description) value="target.value")}}>{{this.description}}</textarea>
              </div>
              <div class="control-group">
                <label>Punkte-Kosten</label>
                <input type="number" min="0" required class="input-small" {{on "input" (action (mut this.cost) value="target.value")}} value={{this.cost}} />
              </div>
              <div class="control-group">
                <label>Typ</label>
                <select class="input-medium" {{on "change" (action (mut this.rewardType) value="target.value")}}>
                  <option value="manual" selected={{eq this.rewardType "manual"}}>Manuell (Lieferung)</option>
                  <option value="title" selected={{eq this.rewardType "title"}}>Benutzertitel</option>
                  <option value="group" selected={{eq this.rewardType "group"}}>Gruppe beitreten</option>
                  <option value="avatar_frame" selected={{eq this.rewardType "avatar_frame"}}>Avatar-Rahmen</option>
                </select>
              </div>
              <div class="control-group">
                <label>Wert (z. B. Titeltext, Gruppen-ID, Rahmen-URL)</label>
                <input type="text" class="input-large" {{on "input" (action (mut this.rewardValue) value="target.value")}} value={{this.rewardValue}} />
              </div>
              <div class="control-group">
                <label>FontAwesome-Icon (z.B. gift, crown, shield-halved)</label>
                <input type="text" class="input-medium" {{on "input" (action (mut this.iconName) value="target.value")}} value={{this.iconName}} />
              </div>

              <div class="form-actions">
                <DButton type="submit" @disabled={{this.saving}} class="btn-primary" @label="gamification.save" />
                <DButton @action={{this.cancelEdit}} class="btn-default" @label="gamification.cancel" />
              </div>
            </form>
          {{else}}
            <div class="admin-reward-list-header">
              <DButton @action={{this.startCreate}} class="btn-primary" @icon="plus" @label="gamification.leaderboard.new" />
            </div>

            <table class="table admin-rewards-table">
              <thead>
                <tr>
                  <th>Icon</th>
                  <th>Name</th>
                  <th>Kosten</th>
                  <th>Typ</th>
                  <th>Aktionen</th>
                </tr>
              </thead>
              <tbody>
                {{#each this.rewards as |reward|}}
                  <tr>
                    <td>{{icon reward.icon}}</td>
                    <td>
                      <strong>{{reward.name}}</strong>
                      {{#if reward.description}}
                        <br/><small>{{reward.description}}</small>
                      {{/if}}
                    </td>
                    <td>{{reward.cost}}</td>
                    <td><span class="reward-type-badge">{{reward.reward_type}}</span></td>
                    <td>
                      <DButton @action={{fn this.startEdit reward}} class="btn-default btn-small" @icon="pencil" />
                      <DButton @action={{fn this.deleteReward reward}} class="btn-danger btn-small" @icon="trash-can" />
                    </td>
                  </tr>
                {{/each:else}}
                  <tr>
                    <td colspan="5" class="no-results">Keine Gegenstände angelegt.</td>
                  </tr>
                {{/each}}
              </tbody>
            </table>
          {{/if}}
        </div>
      {{else}}
        <div class="admin-redemptions-view">
          <table class="table admin-redemptions-table">
            <thead>
              <tr>
                <th>Datum</th>
                <th>Benutzer</th>
                <th>Item</th>
                <th>Status</th>
                <th>Aktionen</th>
              </tr>
            </thead>
            <tbody>
              {{#each this.redemptions as |red|}}
                <tr>
                  <td>{{red.created_at}}</td>
                  <td><strong>{{red.user.username}}</strong></td>
                  <td>{{red.reward.name}} ({{red.reward.cost}} Pkt.)</td>
                  <td><span class="status-badge {{red.status}}">{{red.status}}</span></td>
                  <td>
                    {{#if (eq red.status "pending")}}
                      <DButton
                        @action={{fn this.approveRedemption red}}
                        @disabled={{get this.processingRedemption red.id}}
                        class="btn-primary btn-small"
                        @icon="check"
                        @label="Einlösen/Ausliefern"
                      />
                      <DButton
                        @action={{fn this.rejectRedemption red}}
                        @disabled={{get this.processingRedemption red.id}}
                        class="btn-danger btn-small"
                        @icon="xmark"
                        @label="Ablehnen & Erstatten"
                      />
                    {{/if}}
                  </td>
                </tr>
              {{/each:else}}
                <tr>
                  <td colspan="5" class="no-results">Keine Bestellungen vorhanden.</td>
                </tr>
              {{/each}}
            </tbody>
          </table>
        </div>
      {{/if}}
    </div>
  </template>
}
