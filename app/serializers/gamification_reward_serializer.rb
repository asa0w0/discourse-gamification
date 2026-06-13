# frozen_string_literal: true

class GamificationRewardSerializer < ApplicationSerializer
  attributes :id, :name, :description, :cost, :reward_type, :reward_value, :icon
end
