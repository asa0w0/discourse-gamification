# frozen_string_literal: true

class UserScoreSerializer < BasicUserSerializer
  attributes :total_score, :position, :position_change
end
