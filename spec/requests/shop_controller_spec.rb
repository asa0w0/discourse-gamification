# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseGamification::ShopController do
  fab!(:user) { Fabricate(:user) }
  fab!(:other_user) { Fabricate(:user) }
  fab!(:leaderboard) { Fabricate(:gamification_leaderboard) }
  fab!(:title_reward) do
    DiscourseGamification::GamificationReward.create!(
      name: "Super Hero",
      cost: 50,
      reward_type: :title,
      reward_value: "Hero"
    )
  end
  fab!(:manual_reward) do
    DiscourseGamification::GamificationReward.create!(
      name: "T-Shirt",
      cost: 100,
      reward_type: :manual
    )
  end

  before do
    SiteSetting.discourse_gamification_enabled = true
    SiteSetting.day_visited_score_value = 0
    sign_in(user)
  end

  describe "#index" do
    it "returns the shop index data successfully" do
      # Give user some points
      DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: Date.today,
        points: 200
      )
      DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)
      DiscourseGamification::LeaderboardCachedView.create_all

      get "/leaderboard/shop.json"
      expect(response.status).to eq(200)

      data = response.parsed_body
      expect(data["balance"]).to eq(200)
      expect(data["rewards"].map { |r| r["id"] }).to include(title_reward.id, manual_reward.id)
      expect(data["inventory"]).to be_empty
    end
  end

  describe "#buy" do
    it "fails if user has insufficient points" do
      post "/leaderboard/shop/buy.json", params: { reward_id: manual_reward.id }
      expect(response.status).to eq(422)
      expect(response.parsed_body["errors"]).to include(I18n.t("gamification.shop.insufficient_points"))
    end

    it "buys a reward successfully if user has enough points" do
      # Give user points
      DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: Date.today,
        points: 150
      )
      DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)
      DiscourseGamification::LeaderboardCachedView.create_all

      initial_score = user.reload.gamification_score

      expect {
        post "/leaderboard/shop/buy.json", params: { reward_id: manual_reward.id }
      }.to change { DiscourseGamification::GamificationInventoryItem.count }.by(1)

      expect(response.status).to eq(200)

      # Points should be deducted immediately
      DiscourseGamification::LeaderboardCachedView.new(leaderboard).refresh
      user.reload
      expect(user.gamification_score).to eq(initial_score - manual_reward.cost)

      inventory_item = DiscourseGamification::GamificationInventoryItem.last
      expect(inventory_item.user_id).to eq(user.id)
      expect(inventory_item.reward_id).to eq(manual_reward.id)
      expect(inventory_item.status).to eq("pending")
    end
  end

  describe "#toggle_equip" do
    let!(:inventory_item) do
      DiscourseGamification::GamificationInventoryItem.create!(
        user_id: user.id,
        reward_id: title_reward.id,
        status: :delivered,
        equipped: false
      )
    end

    it "equips the title and updates user title" do
      post "/leaderboard/shop/inventory/#{inventory_item.id}/toggle_equip.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["equipped"]).to be(true)

      user.reload
      expect(user.title).to eq("Hero")
    end

    it "unequips the title and clears user title" do
      inventory_item.update!(equipped: true)
      user.update!(title: "Hero")

      post "/leaderboard/shop/inventory/#{inventory_item.id}/toggle_equip.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body["equipped"]).to be(false)

      user.reload
      expect(user.title).to be_nil
    end
  end

  describe "#user_inventory" do
    let!(:delivered_item) do
      DiscourseGamification::GamificationInventoryItem.create!(
        user_id: other_user.id,
        reward_id: title_reward.id,
        status: :delivered,
        equipped: true
      )
    end
    let!(:pending_item) do
      DiscourseGamification::GamificationInventoryItem.create!(
        user_id: other_user.id,
        reward_id: manual_reward.id,
        status: :pending,
        equipped: false
      )
    end

    it "returns public items (delivered status only) for any user" do
      get "/leaderboard/user-inventory/#{other_user.username}.json"
      expect(response.status).to eq(200)

      data = response.parsed_body
      expect(data.map { |i| i["id"] }).to contain_exactly(delivered_item.id)
    end
  end
end
