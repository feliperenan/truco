defmodule ImageUploader.Repo do
  use Ecto.Repo,
    otp_app: :image_uploader,
    adapter: Ecto.Adapters.Postgres
end
