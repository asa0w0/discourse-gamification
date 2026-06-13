# frozen_string_literal: true

module ::DiscourseGamification
  class WikiEdit < Scorable
    def self.enabled?
      SiteSetting.wiki_edit_score_value > 0
    end

    def self.score_multiplier
      SiteSetting.wiki_edit_score_value
    end

    def self.category_filter
      return "" if scorable_category_list.empty?

      <<~SQL
        AND t.category_id IN (#{scorable_category_list})
      SQL
    end

    def self.query
      <<~SQL
        SELECT
          pr.user_id AS user_id,
          date_trunc('day', pr.created_at) AS date,
          COUNT(*) * #{score_multiplier} AS points
        FROM
          post_revisions AS pr
        INNER JOIN posts AS p
          ON p.id = pr.post_id
        INNER JOIN topics AS t
          ON t.id = p.topic_id
          #{category_filter}
        WHERE
          p.wiki = TRUE AND
          p.deleted_at IS NULL AND
          t.deleted_at IS NULL AND
          t.archetype <> 'private_message' AND
          pr.user_id <> p.user_id AND
          pr.created_at >= :since
        GROUP BY
          1, 2
      SQL
    end
  end
end
