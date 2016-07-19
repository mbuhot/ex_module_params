# Parameterized Modules for Elixir

This library allows you to declare module level parameters that can be provided when
the module is used.  This allows tricky dependencies to be swapped out for tests,
without requiring any dynamic lookups.

## Getting Started

Add ex_module_params to mix deps:

```Elixir
defp deps do
  [
    {:ex_module_params,  github: "mbuhot/ex_module_params"}
  ]
end
```


## Usage

`ModuleParams` exports a `defmodule/3` macro that allows defining modules with parameters.
The parameters are specified as keyword arguments with default values.

```Elixir
use ModuleParams

defmodule MyModule, S3: MyS3Client do

  def generate_report(data) do
    S3.put_object!("my_bucket", "report.xml", "<yolo>#{data}</yolo>")
  end
end
```

To use the module, it must be instantiated with `use`.
This is the place where the default values for modules can be overridden, eg with fakes for testing.
`as: Alias` can be used to give the instantiated module an alias within the current scope.


```Elixir
defmodule MyModuleTest do
  use ExUnit.Case

  defmodule FakeS3 do
    def put_object!("my_bucket", "report.xml", contents) do
      send(self, contents)
    end
  end

  use MyModule, S3: FakeS3, as: MyTestModule

  test "Uploads to S3" do
    MyTestModule.generate_report("Holla!")
    assert_received("<yolo>Holla!</yolo>")
  end
end
```

## Creating a registry

If you have a tree of modules which all declare their dependencies as parameters,
eventually you have to instantiate the top level module.

This can be put configured in a single registry module, which can then be used from the top level
application entry point:

```Elixir
defmodule A do
  @moduledoc "A leaf module"
  def yolo, do: "Heeeyy!"
end

defmodule B, A: A do
  @moduledoc "Intermediate module, depends on A"
  def pokemon(x), do: "#{A.yolo} #{x}"
end

defmodule C, B: nil do
  @moduledoc "Intermediate module, depends on B"
  def catchemall(y) do
    B.pokemon("Do u even pokemon, #{y}?")
  end
end

defmodule D, C: nil do
  @moduledoc "Intermediate module, depends on C"
  def over9000(z) do
    C.catchemall("It over #{z} thousand!!!")
  end
end

defmodule Registry do
  @moduledoc "Module registry"

  use B, A: A, as: B
  use C, B: B, as: C
  use D, C: C, as: D

  defmacro __using__(name) do
    val = __ENV__.aliases[Module.concat(elem(name,2))]
    quote do
      alias unquote(val), as: unquote(name)
    end
  end
end

defmodule MainModule do
  @moduledoc "Top level module, uses the registry to resolve an instance of D"
  use Registry, D

  @doc ~S"""
  Runs the app.

  ## Examples

  iex> MainModule.run
  "Heeeyy! Do u even pokemon, It over 123 thousand!!!?"
  """
  def run do
    D.over9000("123")
  end
end
```

## License

Copyright (c) 2016 Michael Buhot (m.buhot@gmail.com), see LICENSE.md for details
