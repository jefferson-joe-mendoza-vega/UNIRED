class AddImageUrlToPublicacions < ActiveRecord::Migration[7.1]
  def change
    add_column :publicacions, :image_url, :string
  end
end
