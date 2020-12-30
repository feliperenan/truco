defmodule ImageUploader do
  @moduledoc """
  Provide functions for uploading images to somewhere.
  """

  alias ImageUploader.{Repo, Image}

  @doc """
  Upload all PNG images inside of `priv/assets/images/deck` to IMGBB.
  """
  @spec upload_deck_to_imgbb!() :: :ok
  def upload_deck_to_imgbb! do
    file_paths = Path.wildcard("priv/assets/images/deck/**.png")

    for filepath <- file_paths do
      IMGBBClient.Uploader.upload_image!(filepath)
    end
    |> insert_all_images()

    :ok
  end

  @doc """
  Insert the given list of images on the database.
  """
  @spec insert_all_images(list(map())) :: :ok
  def insert_all_images(image_params_list) do
    Repo.insert_all(Image, image_params_list, on_conflict: {:replace, [:url, :thumb_url]}, conflict_target: [:key])

    :ok
  end

  @doc """
  Get image according to the given opts.
  """
  @spec get_image_by(Keyword.t() | map()) :: Image.t()
  def get_image_by(opts), do: Repo.get_by(Image, opts)
end
