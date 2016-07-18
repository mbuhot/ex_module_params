defmodule ParameterizedModuleTest do
  use ExUnit.Case
  doctest ParameterizedModule

  test "Can instantiate with substitued alias" do
    defmodule Elixir.FakeIO do
      def puts(x), do: send(self, x)
    end

    use ModA, O: FakeIO, as: TestModA
    TestModA.launch_missiles("HELLO")
    assert_received("hello")
  end

  test "Can instantiate with different params again" do
    defmodule Elixir.EvenBetterIO do
      def puts(x), do: send(self, x <> x)
    end

    use ModA, O: EvenBetterIO
    ModA.launch_missiles("WORLD")
    assert_received("worldworld")
  end

  test "Can instanitate with defaults" do
    use ModA
    ModA.launch_missiles("GOODBYE")
  end
end
