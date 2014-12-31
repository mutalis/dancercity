class AddHtmlCodeToPost < ActiveRecord::Migration
  def change
    add_column :posts, :html_code, :text
  end
end
