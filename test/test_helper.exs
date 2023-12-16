Mimic.copy(ExStatusCheck.Utils)
Mimic.copy(Req)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(ExStatusCheck.Repo, :manual)
