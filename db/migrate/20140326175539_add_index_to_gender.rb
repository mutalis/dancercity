class AddIndexToGender < ActiveRecord::Migration
    def up
      execute %{
        create index index_on_users_gender ON users using gin(to_tsvector('simple', gender))
      }
    end

    def down
      execute %{drop index index_on_users_gender}
    end
end
