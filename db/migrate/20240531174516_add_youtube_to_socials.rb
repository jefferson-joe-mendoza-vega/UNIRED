class AddYoutubeToSocials < ActiveRecord::Migration[7.1]
  def change
    add_column :socials, :youtube, :string
  end
end
