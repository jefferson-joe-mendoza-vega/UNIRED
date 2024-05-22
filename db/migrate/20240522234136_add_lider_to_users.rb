class AddLiderToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :lider, :boolean, default: false
  end
end
