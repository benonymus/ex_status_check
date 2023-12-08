defmodule ExStatusCheck.Checks.Check do
  use Ecto.Schema
  import Ecto.Changeset

  schema "checks" do
    field :success, :boolean, default: false
    belongs_to :page, ExStatusCheck.Pages.Page

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(page, attrs) do
    page
    |> cast(attrs, [:success, :page_id])
    |> validate_required([:success, :page_id])
  end
end
