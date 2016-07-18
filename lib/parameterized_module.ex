defmodule ParameterizedModule do

  @doc """
  Makes defmodule/3 available for module definition.
  """
  defmacro __using__(_) do
    quote do
      import ParameterizedModule, only: [defmodule: 3]
    end
  end

  @doc """
  Declare a module with parameters.

  Initially, the only parameters allowed are other module names.

  ## Example

  ```Elixir
  defmodule MyModule, S: String, O: IO do
    def my_func(x) do
      x |> S.downcase |> O.puts
    end
  end
  ```

  This declares a module with the given `name`, however it will not contain
  the declarations given in `body`, only an exported macro `__using__` that can be
  used to instantiate the module.

  Calling the generated `__using__` macro will generate an instantiation of the module body,
  and alias the result in the calling module.

  ## Example

  ```Elixir
  use MyModule, S: String, O: FakeIO

  MyModule.my_func("FOO")
  ```

  ## Example

  `as: Alias` can be given as an argument to `__using__` to customize the alias within the calling module.

  ```Elixir
  use MyModule, S: String, O: FakeIO, as: M

  M.my_func("FOO")
  ```
  """
  defmacro defmodule(name, defaults, body) do
    name = concat_aliases(name)
    env = Macro.Env.location(__CALLER__)
    contents = module_contents(name, body, env, defaults)
    Module.create(name, contents, env)
    :ok
  end

  # Generates the __using__ macro for a parameterized module
  # name: module name atom
  # body: module body, as passed to `defmodule/3`
  # env: module location env, suitable for passing to Module.create/3
  # defaults: default aliases, as passed to `defmodule/3`
  defp module_contents(name, body, env, defaults) do
    [
      do: {
        :defmacro, [], [
          {:__using__, [], [{:opts, [], Elixir}]}, [
            do: {
              {:., [], [{:__aliases__, [alias: false], [:ParameterizedModule]}, :using]}, [],
              [name, {:quote, [], [body]}, env, defaults, {:opts, [], Elixir}]
            }
          ]
        ]
      }
    ]
  end

  def using(name, body, env, defaults, opts) do
    args = resolve_args(defaults, opts)
    mangled_name = new(name, body, env, args)
    make_alias(mangled_name, alias_name(name, opts))
  end

  defp resolve_args(defaults, opts) do
    opts
    |> Keyword.drop([:as])
    |> Keyword.merge(defaults, fn (_k, v1, _v2) -> v1 end)
    |> Enum.map(fn {k,v} -> {k, concat_aliases(v)} end)
  end

  defp alias_name(name, opts) do
    opts
    |> Keyword.get(:as, name)
    |> concat_aliases
  end

  defp new(name, body, env, args) do
    mangled_name = mangle_name(name, args)
    unless :code.is_loaded(mangled_name) do
      full_body = inject_aliases(args, body)
      Module.create(mangled_name, full_body, env)
    end
    mangled_name
  end

  defp mangle_name(name, args) do
    vals = Keyword.values(args)
    "#{name}(#{Enum.join(vals,",")})" |> String.to_atom
  end

  defp inject_aliases(args, body) do
    aliases = make_aliases(args)
    quote do
      unquote(aliases)
      unquote(body)
    end
  end

  defp concat_aliases({:__aliases__,_,v}), do: Module.concat(v)
  defp concat_aliases(x), do: x

  defp make_aliases(args) when is_list(args) do
    {:__block__, [], Enum.map(args, fn {k,v} -> make_alias(v, Module.concat([k])) end)}
  end

  defp make_alias(from, to) when is_atom(from) and is_atom(to) do
    quote do
      alias unquote(from), as: unquote(to)
    end
  end
end
