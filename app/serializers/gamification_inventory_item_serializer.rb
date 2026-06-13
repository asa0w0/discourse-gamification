# frozen_string_literal: true

class GamificationInventoryItemSerializer < ApplicationSerializer
  attributes :id, :user_id, :equipped, :status, :created_at

  has_one :reward, serializer: GamificationRewardSerializer, embed: :objects
end
