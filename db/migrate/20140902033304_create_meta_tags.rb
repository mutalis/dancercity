class CreateMetaTags < ActiveRecord::Migration
  def change
    create_table :meta_tags do |t|
      t.string :name
      t.string :content
      t.references :post, index: true

      t.timestamps
    end
  end
end
