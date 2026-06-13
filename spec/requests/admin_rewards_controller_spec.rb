# frozen_string_literal: true

require "rails_helper"

RSpec.describe DiscourseGamification::AdminRewardsController do
  fab!(:admin) { Fabricate(:admin) }
  fab!(:user) { Fabricate(:user) }
  fab!(:leaderboard) { Fabricate(:gamification_leaderboard) }
  fab!(:reward) do
    DiscourseGamification::GamificationReward.create!(
      name: "T-Shirt",
      cost: 100,
      reward_type: :manual
    )
  end

  before do
    SiteSetting.discourse_gamification_enabled = true
    SiteSetting.day_visited_score_value = 0
    sign_in(admin)
  end

  describe "#rewards" do
    it "returns all rewards successfully" do
      get "/admin/plugins/discourse-gamification/rewards.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.map { |r| r["id"] }).to contain_exactly(reward.id)
    end
  end

  describe "#create_reward" do
    it "creates a new reward successfully" do
      expect {
        post "/admin/plugins/discourse-gamification/rewards.json", params: {
          name: "Coffee Mug",
          cost: 30,
          reward_type: "manual",
          icon: "cup-togo"
        }
      }.to change { DiscourseGamification::GamificationReward.count }.by(1)

      expect(response.status).to eq(200)
      new_reward = DiscourseGamification::GamificationReward.last
      expect(new_reward.name).to eq("Coffee Mug")
      expect(new_reward.cost).to eq(30)
      expect(new_reward.icon).to eq("cup-togo")
    end
  end

  describe "#update_reward" do
    it "updates an existing reward successfully" do
      put "/admin/plugins/discourse-gamification/rewards/#{reward.id}.json", params: {
        id: reward.id,
        name: "Premium T-Shirt",
        cost: 150,
        reward_type: "manual",
        icon: "shirt"
      }

      expect(response.status).to eq(200)
      reward.reload
      expect(reward.name).to eq("Premium T-Shirt")
      expect(reward.cost).to eq(150)
      expect(reward.icon).to eq("shirt")
    end
  end

  describe "#delete_reward" do
    it "deletes an existing reward successfully" do
      expect {
        delete "/admin/plugins/discourse-gamification/rewards/#{reward.id}.json"
      }.to change { DiscourseGamification::GamificationReward.count }.by(-1)

      expect(response.status).to eq(200)
    end
  end

  describe "redemption handling" do
    let!(:redemption) do
      DiscourseGamification::GamificationInventoryItem.create!(
        user_id: user.id,
        reward_id: reward.id,
        status: :pending,
        equipped: false
      )
    end

    it "lists redemptions successfully" do
      get "/admin/plugins/discourse-gamification/redemptions.json"
      expect(response.status).to eq(200)
      expect(response.parsed_body.map { |r| r["id"] }).to contain_exactly(redemption.id)
    end

    it "approves a pending redemption" do
      post "/admin/plugins/discourse-gamification/redemptions/#{redemption.id}/approve.json"
      expect(response.status).to eq(200)
      redemption.reload
      expect(redemption.status).to eq("delivered")
    end

    it "rejects a pending redemption and refunds points" do
      # Set user score to 0 (assume they already paid 100 points)
      # We want to check they are refunded +100 points
      DiscourseGamification::GamificationScoreEvent.create!(
        user_id: user.id,
        date: Date.today,
        points: 0
      )
      DiscourseGamification::GamificationScore.calculate_scores(since_date: Date.today)
      DiscourseGamification::LeaderboardCachedView.create_all

      expect {
        post "/admin/plugins/discourse-gamification/redemptions/#{redemption.id}/reject.json"
      }.to change { DiscourseGamification::GamificationScoreEvent.count }.by(1)

      expect(response.status).to eq(200)
      redemption.reload
      expect(redemption.status).to eq("rejected")

      # Checks that points are refunded
      DiscourseGamification::LeaderboardCachedView.new(leaderboard).refresh
      user.reload
      expect(user.gamification_score).to eq(100)
    end
  end
end
