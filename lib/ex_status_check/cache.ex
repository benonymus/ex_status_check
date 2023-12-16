defmodule ExStatusCheck.Cache do
  @moduledoc false
  use Nebulex.Cache,
    otp_app: :ex_status_check,
    adapter: Nebulex.Adapters.Local
end
