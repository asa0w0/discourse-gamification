# frozen_string_literal: true

RSpec.describe DiscourseGamification::WikiEdit do
  fab!(:topic) { Fabricate(:topic) }
  fab!(:post_creator) { Fabricate(:user) }
  fab!(:wiki_post) { Fabricate(:post, topic: topic, user: post_creator, wiki: true) }
  fab!(:editor) { Fabricate(:user) }

  before do
    SiteSetting.wiki_edit_score_value = 3
  end

  it "is enabled when score value is positive" do
    expect(described_class).to be_enabled

    SiteSetting.wiki_edit_score_value = 0
    expect(described_class).not_to be_enabled
  end

  describe "scoring query" do
    def query_results
      DB.query(described_class.query, since: 2.days.ago)
    end

    it "scores wiki post edits correctly" do
      # Edit by another user
      PostRevision.create!(
        user_id: editor.id,
        post_id: wiki_post.id,
        number: 2,
        created_at: 1.day.ago
      )

      expect(query_results).to contain_exactly(
        have_attributes(user_id: editor.id, date: 1.day.ago.beginning_of_day.to_date, points: 3)
      )
    end

    it "does not score edits made by the original post creator" do
      # Edit by post creator
      PostRevision.create!(
        user_id: post_creator.id,
        post_id: wiki_post.id,
        number: 2,
        created_at: 1.day.ago
      )

      expect(query_results).to be_empty
    end
  end
end
