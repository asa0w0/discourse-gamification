# frozen_string_literal: true

module ::DiscourseGamification
  class ShopController < ::ApplicationController
    requires_plugin PLUGIN_NAME
    before_action :ensure_logged_in, except: [:user_inventory]

    def index
      rewards = GamificationReward.all.order(cost: :asc)
      inventory = GamificationInventoryItem.where(user_id: current_user.id).includes(:reward)

      render_serialized(
        {
          rewards: rewards,
          inventory: inventory,
          balance: current_user.gamification_score
        },
        ShopIndexSerializer,
        root: false
      )
    end

    def buy
      params.require(:reward_id)
      reward = GamificationReward.find(params[:reward_id])

      if current_user.gamification_score < reward.cost
        return render_json_error(I18n.t("gamification.shop.insufficient_points"))
      end

      inventory_item = nil
      ActiveRecord::Base.transaction do
        # Create negative score event to deduct points
        GamificationScoreEvent.create!(
          user_id: current_user.id,
          date: Date.today,
          points: -reward.cost,
          description: I18n.t("gamification.shop.redeemed_item", name: reward.name)
        )

        status = reward.manual? ? :pending : :delivered

        inventory_item = GamificationInventoryItem.create!(
          user_id: current_user.id,
          reward_id: reward.id,
          status: status,
          equipped: false
        )

        if reward.group?
          group = Group.find_by(id: reward.reward_value.to_i)
          if group
            group.add(current_user)
          end
        end
      end

      # Recalculate scores so the new balance is reflected immediately
      GamificationScore.calculate_scores(since_date: Date.today)

      render_serialized(inventory_item, GamificationInventoryItemSerializer, root: false)
    end

    def toggle_equip
      params.require(:id)
      inventory_item = GamificationInventoryItem.find_by(id: params[:id], user_id: current_user.id)
      raise Discourse::NotFound unless inventory_item
      raise Discourse::InvalidAccess unless inventory_item.reward.title? || inventory_item.reward.avatar_frame?

      if inventory_item.equipped?
        GamificationInventoryItem.unequip_item(current_user, inventory_item)
      else
        GamificationInventoryItem.equip_item(current_user, inventory_item)
      end

      inventory_item.reload
      render_serialized(inventory_item, GamificationInventoryItemSerializer, root: false)
    end

    def user_inventory
      params.require(:username)
      user = User.find_by_username(params[:username])
      raise Discourse::NotFound unless user

      inventory = GamificationInventoryItem
        .where(user_id: user.id)
        .where(status: :delivered)
        .includes(:reward)

      render_serialized(inventory, GamificationInventoryItemSerializer, root: false)
    end
  end
end
