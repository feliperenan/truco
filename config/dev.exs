use Mix.Config

# Configure your database
config :image_uploader, ImageUploader.Repo,
  username: "postgres",
  password: "postgres",
  database: "image_uploader_dev",
  hostname: "localhost",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

imgbb_api_key =
  System.get_env("IMGBB_API_KEY") ||
    raise """
    environment variable IMGBB_API_KEY is missing.
    """

config :image_uploader, :imgbb, api_key: imgbb_api_key
