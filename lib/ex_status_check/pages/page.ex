defmodule ExStatusCheck.Pages.Page do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule URLSlug do
    use EctoAutoslugField.Slug, from: :slug_base, to: :slug
  end

  schema "pages" do
    field :url, :string
    field :slug_base, :string, virtual: true
    field :slug, URLSlug.Type

    belongs_to :oban_job, Oban.Job

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:url])
    |> validate_required([:url])
  end

  def changeset_with_uri(page, attrs) do
    page
    |> changeset(attrs)
    |> check_url()
    |> URLSlug.maybe_generate_slug()
    |> URLSlug.unique_constraint()
  end

  def oban_job_id_changeset(page, attrs) do
    page
    |> cast(attrs, [:oban_job_id])
    |> validate_required([:oban_job_id])
  end

  defp check_url(%Ecto.Changeset{valid?: true} = changeset) do
    url = get_field(changeset, :url)

    with {:ok, %URI{scheme: scheme, host: host, path: path} = uri} <- URI.new(url),
         {:scheme, false} <- {:scheme, is_nil(scheme)},
         false <- is_nil(host),
         {:path, false} <- {:path, is_nil(path)},
         :inet.gethostbyname(to_charlist(host)) do
      url =
        %URI{uri | scheme: "https", query: nil}
        |> URI.to_string()
        |> String.downcase()

      changeset
      |> force_change(:url, url)
      |> force_change(:slug_base, host <> path)
    else
      {:scheme, true} ->
        changeset
        |> force_change(:url, "https://" <> url)
        |> check_url()

      {:path, true} ->
        changeset
        |> force_change(:url, url <> "/")
        |> check_url()

      _ ->
        add_error(changeset, :url, "invalid")
    end
  end

  defp check_url(changeset), do: changeset
end
