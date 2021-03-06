defmodule Mix.Mandarin.Context do
  @moduledoc false

  alias Mix.Mandarin.{Context, Schema}

  defstruct name: nil,
            module: nil,
            schema: nil,
            alias: nil,
            base_module: nil,
            web_module: nil,
            basename: nil,
            file: nil,
            test_file: nil,
            dir: nil,
            generate?: true,
            context_app: nil,
            opts: []

  def valid?(context) do
    context =~ ~r/^[A-Z]\w*(\.[A-Z]\w*)*$/
  end

  def new(context_name, %Schema{} = schema, opts) do
    ctx_app = opts[:context_app] || Mix.Mandarin.context_app()
    base = Module.concat([Mix.Mandarin.context_base(ctx_app)])
    module = Module.concat(base, context_name)
    alias = Module.concat([module |> Module.split() |> List.last()])
    basedir = Mandarin.Naming.underscore(context_name)
    basename = Path.basename(basedir)
    dir = Mix.Mandarin.context_lib_path(ctx_app, basedir)
    test_dir = Mix.Mandarin.context_test_path(ctx_app, basedir)
    file = Path.join([dir, basename <> ".ex"])
    test_file = Path.join([test_dir, basename <> "_test.exs"])
    generate? = Keyword.get(opts, :context, true)

    %Context{
      name: context_name,
      module: module,
      schema: schema,
      alias: alias,
      base_module: base,
      web_module: web_module(),
      basename: basename,
      file: file,
      test_file: test_file,
      dir: dir,
      generate?: generate?,
      context_app: ctx_app,
      opts: opts
    }
  end

  def pre_existing?(%Context{file: file}), do: File.exists?(file)

  def pre_existing_tests?(%Context{test_file: file}), do: File.exists?(file)

  def function_count(%Context{file: file}) do
    {_ast, count} =
      file
      |> File.read!()
      |> Code.string_to_quoted!()
      |> Macro.postwalk(0, fn
        {:def, _, _} = node, count -> {node, count + 1}
        node, count -> {node, count}
      end)

    count
  end

  def file_count(%Context{dir: dir}) do
    dir
    |> Path.join("**/*.ex")
    |> Path.wildcard()
    |> Enum.count()
  end

  defp web_module do
    base = Mix.Mandarin.base()

    cond do
      Mix.Mandarin.context_app() != Mix.Mandarin.otp_app() ->
        Module.concat([base])

      String.ends_with?(base, "Web") ->
        Module.concat([base])

      true ->
        Module.concat(["#{base}Web"])
    end
  end
end
