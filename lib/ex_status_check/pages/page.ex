defmodule ExStatusCheck.Pages.Page do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  defmodule URLSlug do
    @moduledoc false
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
         {:host, false} <- {:host, is_nil(host)},
         {:ok, _} <- :inet.gethostbyname(to_charlist(host)) do
      path = path || "/"

      url =
        %URI{uri | scheme: "https", path: path, query: nil}
        |> URI.to_string()
        |> String.downcase()

      changeset
      |> force_change(:url, url)
      |> force_change(:slug_base, host <> path)
    else
      {missing_thing, true} ->
        add_error(changeset, :url, "invalid url - missing #{missing_thing}")

      err ->
        add_error(changeset, :url, "invalid url - #{inspect(err)}")
    end
  end

  defp check_url(changeset), do: changeset
end
