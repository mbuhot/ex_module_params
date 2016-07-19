use ModuleParams

defmodule A do
  def yolo, do: "Heeeyy!"
end

defmodule B, A: A do
  def pokemon(x), do: "#{A.yolo} #{x}"
end

defmodule C, B: nil do
  def catchemall(y) do
    B.pokemon("Do u even pokemon, #{y}?")
  end
end

defmodule D, C: nil do
  def over9000(z) do
    C.catchemall("It over #{z} thousand!!!")
  end
end

defmodule Registry do
  use B, A: A, as: B
  use C, B: B, as: C
  use D, C: C, as: D

  defmacro __using__(name) do
    mangled_name = __ENV__.aliases[Module.concat(elem(name,2))]
    quote do
      alias unquote(mangled_name), as: unquote(name)
    end
  end
end

defmodule MainModule do
  use Registry, D

  def run do
    D.over9000("123")
  end
end


defmodule ModuleParamsTest do
  use ExUnit.Case
  doctest ModuleParams

  test "Bootstrap main module" do
    assert  MainModule.run == "Heeeyy! Do u even pokemon, It over 123 thousand!!!?"
  end

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
