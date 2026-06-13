# frozen_string_literal: true

class CreateGamificationRewardsAndInventory < ActiveRecord::Migration[7.2]
  def change
    create_table :gamification_rewards do |t|
      t.string :name, null: false
      t.text :description
      t.integer :cost, null: false
      t.integer :reward_type, null: false, default: 0
      t.string :reward_value
      t.string :icon, null: false, default: "gift"
      t.timestamps
    end

    create_table :gamification_inventory do |t|
      t.integer :user_id, null: false
      t.integer :reward_id, null: false
      t.boolean :equipped, null: false, default: false
      t.integer :status, null: false, default: 1
      t.timestamps
    end

    add_index :gamification_inventory, :user_id
    add_index :gamification_inventory, :reward_id
    add_index :gamification_inventory, [:user_id, :reward_id]
  end
end
