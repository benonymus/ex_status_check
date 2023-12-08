defmodule ExStatusCheck.Repo.Migrations.CreatePages do
  use Ecto.Migration

  def change do
    create table(:pages) do
      add :url, :string, collate: :nocase, null: false
      add :slug, :string, collate: :nocase, null: false

      add :oban_job_id, references(:oban_jobs, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index("pages", [:url])
    create unique_index("pages", [:slug])
  end
end
