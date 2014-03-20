class AddPointIndexToUsers < ActiveRecord::Migration
  def up
    execute %{
      create index index_on_users_location ON users using gist (
        ST_GeographyFromText(
          'SRID=4326;POINT(' || users.longitude || ' ' || users.latitude || ')'
        )
      )
    }
  end

  def down
    execute %{drop index index_on_users_location}
  end
end
