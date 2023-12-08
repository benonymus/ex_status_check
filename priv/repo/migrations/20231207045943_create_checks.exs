defmodule ExStatusCheck.Repo.Migrations.CreateChecks do
  use Ecto.Migration

  def change do
    create table(:checks) do
      add :success, :boolean, default: false, null: false

      add :page_id, references(:pages, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index("checks", [:page_id])
    create index("checks", [:success])
  end
end
