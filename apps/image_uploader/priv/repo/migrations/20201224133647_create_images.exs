defmodule ImageUploader.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :key, :string, null: false, unique: true
      add :url, :string, null: false
      add :thumb_url, :string, null: false
    end

    create unique_index(:images, [:key])
  end
end
