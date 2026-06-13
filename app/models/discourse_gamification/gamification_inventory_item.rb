# frozen_string_literal: true

module ::DiscourseGamification
  class GamificationInventoryItem < ::ActiveRecord::Base
    self.table_name = "gamification_inventory"

    belongs_to :user
    belongs_to :reward, class_name: "::DiscourseGamification::GamificationReward"

    enum :status, { pending: 0, delivered: 1, rejected: 2 }

    def self.equip_item(user, inventory_item)
      return unless inventory_item.reward.title? || inventory_item.reward.avatar_frame?

      ActiveRecord::Base.transaction do
        # Unequip all items of the same type for this user
        same_type_rewards = GamificationReward.where(reward_type: inventory_item.reward.reward_type)
        same_type_inventory_items = where(user_id: user.id, reward_id: same_type_rewards.select(:id))
        same_type_inventory_items.update_all(equipped: false)

        # Equip this item
        inventory_item.update!(equipped: true)

        # If it is a title, update user's profile title
        if inventory_item.reward.title?
          user.update!(title: inventory_item.reward.reward_value)
        end
      end
    end

    def self.unequip_item(user, inventory_item)
      return unless inventory_item.reward.title? || inventory_item.reward.avatar_frame?

      ActiveRecord::Base.transaction do
        inventory_item.update!(equipped: false)

        if inventory_item.reward.title?
          # If the user currently has this title equipped, remove it
          if user.title == inventory_item.reward.reward_value
            user.update!(title: nil)
          end
        end
      end
    end
  end
end
