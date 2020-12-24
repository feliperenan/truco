defmodule ImageUploader.ImageUploaderTest do
  use ImageUploader.DataCase

  alias ImageUploader.Image

  describe "insert_all_images/1" do
    test "insert a list of images" do
      images = [
        %{key: "image-1", url: "https://image-1.com", thumb_url: "https://image-1-t.com"},
        %{key: "image-2", url: "https://image-2.com", thumb_url: "https://image-2-t.com"}
      ]

      ImageUploader.insert_all_images(images)

      [image_a, image_b] = Repo.all(Image)

      assert image_a.key == "image-1"
      assert image_a.url == "https://image-1.com"
      assert image_a.thumb_url == "https://image-1-t.com"

      assert image_b.key == "image-2"
      assert image_b.url == "https://image-2.com"
      assert image_b.thumb_url == "https://image-2-t.com"
    end

    test "replace duplicated images on conflict" do
      Repo.insert(%Image{key: "image-1", url: "https://old.com", thumb_url: "https://old-t.com"})

      images = [
        %{key: "image-1", url: "https://image-1.com", thumb_url: "https://image-1-t.com"},
        %{key: "image-2", url: "https://image-2.com", thumb_url: "https://image-2-t.com"}
      ]

      ImageUploader.insert_all_images(images)

      image = Repo.get_by(Image, key: "image-1")

      assert image.key == "image-1"
      assert image.url == "https://image-1.com"
      assert image.thumb_url == "https://image-1-t.com"
    end
  end
end
