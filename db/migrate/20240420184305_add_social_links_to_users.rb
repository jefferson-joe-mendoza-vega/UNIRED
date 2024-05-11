class AddSocialLinksToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :facebook, :string
    add_column :users, :whatsapp, :string
    add_column :users, :telegram, :string
  end
end
