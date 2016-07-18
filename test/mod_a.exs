use ParameterizedModule

defmodule ModA, S: String, O: IO do
  def launch_missiles(x) do
    x |> S.downcase |> O.puts
  end
end
