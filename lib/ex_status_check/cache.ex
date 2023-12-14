defmodule ExStatusCheck.Cache do
  use Nebulex.Cache,
    otp_app: :ex_status_check,
    adapter: Nebulex.Adapters.Local
end
