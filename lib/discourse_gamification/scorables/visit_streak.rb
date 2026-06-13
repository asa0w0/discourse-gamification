# frozen_string_literal: true

module ::DiscourseGamification
  class VisitStreak < Scorable
    def self.enabled?
      SiteSetting.visit_streak_score_value > 0
    end

    def self.score_multiplier
      SiteSetting.visit_streak_score_value
    end

    def self.minimum_days
      SiteSetting.visit_streak_minimum_days
    end

    def self.query
      <<~SQL
        WITH visit_groups AS (
          SELECT
            user_id,
            visited_at AS date,
            visited_at - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY visited_at) * INTERVAL '1 day') AS grp
          FROM
            user_visits
        ),
        streak_days AS (
          SELECT
            user_id,
            date,
            ROW_NUMBER() OVER (PARTITION BY user_id, grp ORDER BY date) AS streak_length
          FROM
            visit_groups
        )
        SELECT
          user_id,
          date,
          #{score_multiplier} AS points
        FROM
          streak_days
        WHERE
          streak_length >= #{minimum_days}
          AND date >= :since
      SQL
    end
  end
end
