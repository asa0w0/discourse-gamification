# frozen_string_literal: true

module ::DiscourseGamification
  class AdminRewardsController < Admin::AdminController
    requires_plugin PLUGIN_NAME

    def rewards
      rewards = GamificationReward.all.order(cost: :asc)
      render_serialized(rewards, GamificationRewardSerializer, root: false)
    end

    def create_reward
      params.require([:name, :cost, :reward_type])

      reward = GamificationReward.new(
        name: params[:name],
        description: params[:description],
        cost: params[:cost],
        reward_type: params[:reward_type],
        reward_value: params[:reward_value],
        icon: params[:icon] || "gift"
      )

      if reward.save
        render_serialized(reward, GamificationRewardSerializer, root: false)
      else
        render_json_error(reward)
      end
    end

    def update_reward
      params.require([:id, :name, :cost, :reward_type])
      reward = GamificationReward.find(params[:id])

      reward.update!(
        name: params[:name],
        description: params[:description],
        cost: params[:cost],
        reward_type: params[:reward_type],
        reward_value: params[:reward_value],
        icon: params[:icon] || "gift"
      )

      render_serialized(reward, GamificationRewardSerializer, root: false)
    end

    def delete_reward
      params.require(:id)
      reward = GamificationReward.find(params[:id])
      reward.destroy!
      render json: success_json
    end

    def redemptions
      redemptions = GamificationInventoryItem
        .includes(:reward, :user)
        .order(created_at: :desc)

      render_serialized(
        redemptions,
        AdminRedemptionSerializer,
        root: false
      )
    end

    def approve_redemption
      params.require(:id)
      item = GamificationInventoryItem.find(params[:id])
      item.update!(status: :delivered)
      render_serialized(item, GamificationInventoryItemSerializer, root: false)
    end

    def reject_redemption
      params.require(:id)
      item = GamificationInventoryItem.find(params[:id])

      ActiveRecord::Base.transaction do
        item.update!(status: :rejected)

        # Refund points using a positive score event
        GamificationScoreEvent.create!(
          user_id: item.user_id,
          date: Date.today,
          points: item.reward.cost,
          description: I18n.t("gamification.shop.refund_item", name: item.reward.name)
        )
      end

      # Recalculate scores so the refund is reflected immediately
      GamificationScore.calculate_scores(since_date: Date.today)

      render_serialized(item, GamificationInventoryItemSerializer, root: false)
    end
  end
end
