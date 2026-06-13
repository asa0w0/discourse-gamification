# frozen_string_literal: true

RSpec.describe DiscourseGamification::VisitStreak do
  fab!(:user) { Fabricate(:user) }

  before do
    SiteSetting.visit_streak_score_value = 2
    SiteSetting.visit_streak_minimum_days = 3
  end

  it "is enabled when score value is positive" do
    expect(described_class).to be_enabled

    SiteSetting.visit_streak_score_value = 0
    expect(described_class).not_to be_enabled
  end

  describe "scoring query" do
    def query_results
      DB.query(described_class.query, since: 10.days.ago)
    end

    it "scores consecutive visit streaks correctly" do
      # Day 1: Visit
      UserVisit.create!(user_id: user.id, visited_at: 4.days.ago.to_date, posts_read: 1)
      expect(query_results).to be_empty # Streak = 1, less than 3 days

      # Day 2: Visit
      UserVisit.create!(user_id: user.id, visited_at: 3.days.ago.to_date, posts_read: 1)
      expect(query_results).to be_empty # Streak = 2, less than 3 days

      # Day 3: Visit
      UserVisit.create!(user_id: user.id, visited_at: 2.days.ago.to_date, posts_read: 1)
      expect(query_results).to contain_exactly(
        have_attributes(user_id: user.id, date: 2.days.ago.to_date, points: 2)
      )

      # Day 4: Visit
      UserVisit.create!(user_id: user.id, visited_at: 1.days.ago.to_date, posts_read: 1)
      expect(query_results).to contain_exactly(
        have_attributes(user_id: user.id, date: 2.days.ago.to_date, points: 2),
        have_attributes(user_id: user.id, date: 1.days.ago.to_date, points: 2)
      )
    end

    it "does not score if there is a gap breaking the streak" do
      # Day 1: Visit
      UserVisit.create!(user_id: user.id, visited_at: 6.days.ago.to_date, posts_read: 1)
      # Day 2: Gap (no visit)
      # Day 3: Visit
      UserVisit.create!(user_id: user.id, visited_at: 4.days.ago.to_date, posts_read: 1)
      # Day 4: Visit
      UserVisit.create!(user_id: user.id, visited_at: 3.days.ago.to_date, posts_read: 1)

      # Day 3 was streak 1, Day 4 was streak 2. Neither should get points as minimum is 3.
      expect(query_results).to be_empty
    end
  end
end
