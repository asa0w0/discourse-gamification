# frozen_string_literal: true

class AdminRedemptionSerializer < ApplicationSerializer
  attributes :id, :status, :created_at

  has_one :user, serializer: BasicUserSerializer, embed: :objects
  has_one :reward, serializer: GamificationRewardSerializer, embed: :objects
end
