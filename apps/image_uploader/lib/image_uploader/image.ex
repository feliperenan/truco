defmodule ImageUploader.Image do
  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "images" do
    field :key, :string
    field :url, :string
    field :thumb_url, :string
  end

  @spec changeset(t() | Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def changeset(image, attrs \\ %{}) do
    fields = __schema__(:fields)

    image
    |> cast(attrs, fields)
    |> unique_constraint(:key)
    |> validate_required(fields)
  end
end
