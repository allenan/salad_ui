defmodule SaladChatWeb.Uploads do
  @moduledoc """
  Storage for composer uploads: a directory under the system tmp dir. Like
  the rest of the demo it is not meant to survive for long.
  """

  def dir do
    dir = Path.join(System.tmp_dir!(), "salad_chat_uploads")
    File.mkdir_p!(dir)
    dir
  end

  def path(name), do: Path.join(dir(), name)

  def valid_name?(name), do: Regex.match?(~r/^[A-Za-z0-9_-]+\.[A-Za-z0-9]{1,8}$/, name)

  @doc "Copies an uploaded tmp file into storage and returns its attachment map."
  def store(tmp_path, %Phoenix.LiveView.UploadEntry{} = entry) do
    ext =
      entry.client_name
      |> Path.extname()
      |> String.downcase()
      |> String.replace(~r/[^.a-z0-9]/, "")

    ext = if ext == "", do: ".bin", else: ext
    name = Base.url_encode64(:crypto.strong_rand_bytes(9), padding: false) <> ext
    File.cp!(tmp_path, path(name))

    image? = String.starts_with?(entry.client_type, "image/")

    %{
      name: entry.client_name,
      kind: if(image?, do: :image, else: :file),
      type: ext |> String.trim_leading(".") |> String.upcase(),
      size: entry.client_size,
      url: "/uploads/" <> name,
      alt: entry.client_name
    }
  end
end
