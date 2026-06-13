# frozen_string_literal: true

class ShopIndexSerializer < ApplicationSerializer
  attributes :balance

  has_many :rewards, serializer: GamificationRewardSerializer, embed: :objects
  has_many :inventory, serializer: GamificationInventoryItemSerializer, embed: :objects

  def balance
    object[:balance]
  end

  def rewards
    object[:rewards]
  end

  def inventory
    object[:inventory]
  end
end
