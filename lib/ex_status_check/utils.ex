defmodule ExStatusCheck.Utils do
  @moduledoc false

  def validate_host(host), do: :inet.gethostbyname(Kernel.to_charlist(host))
end
