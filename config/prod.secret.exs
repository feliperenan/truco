use Mix.Config

database_url =
  System.get_env("DATABASE_URL") ||
    raise """
    environment variable DATABASE_URL is missing.
    For example: ecto://USER:PASS@HOST/DATABASE
    """

config :image_uploader, ImageUploader.Repo,
  # ssl: true,
  url: database_url,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

imgbb_api_key =
  System.get_env("IMGBB_API_KEY") ||
    raise """
    environment variable IMGBB_API_KEY is missing.
    """

config :image_uploader, :imgbb, api_key: imgbb_api_key
