# frozen_string_literal: true

module ::DiscourseGamification
  class GamificationReward < ::ActiveRecord::Base
    self.table_name = "gamification_rewards"

    enum :reward_type, { manual: 0, title: 1, group: 2, avatar_frame: 3 }, scopes: false

    validates :name, presence: true
    validates :cost, numericality: { greater_than_or_equal_to: 0 }
  end
end
