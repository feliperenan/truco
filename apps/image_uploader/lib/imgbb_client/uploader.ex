defmodule IMGBBClient.Uploader do
  @api_key Application.get_env(:image_uploader, :imgbb)[:api_key]

  def upload_image!(filepath) do
    url = "https://api.imgbb.com/1/upload"
    payload = build_form_data(filepath)

    url
    |> HTTPoison.post!(payload)
    |> parse_response!()
  end

  defp build_form_data(filepath) do
    {
      :multipart,
      [
        {"key", @api_key},
        {:file, filepath, {"form-data", [{:name, "image"}, {:filename, Path.basename(filepath)}]}, []}
      ]
    }
  end

  defp parse_response!(%HTTPoison.Response{body: body}) do
    %{
      "data" => %{
        "image" => %{
          "filename" => filename,
          "url" => url
        },
        "thumb" => %{
          "url" => thumb_url
        }
      }
    } = Jason.decode!(body)

    %{key: filename, url: url, thumb_url: thumb_url}
  end
end
