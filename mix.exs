defmodule ExMagic.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exmagic,
      description: "Wrapper around libmagic",
      version: "0.0.3",
      package: package(),
      name: "ExMagic",
      source_url: "https://github.com/liamwhite/exmagic",
      elixir: "~> 1.9",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      compilers: [:make, :elixir, :app],
      aliases: aliases(),
      deps: deps(),
    ]
  end

  defp aliases do
    # Execute the usual "mix clean", and also "make clean" in the general clean
    # task.
    [clean: ["clean", "clean.make"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    []
  end

  defp package do
    [
      name: :exmagic,
      files: ["c_src", "lib", "mix.exs", "README*", "LICENSE*", ".file-version"],
      maintainers: ["Andrew Dunham", "Liam P. White"],
      licenses: ["MIT"],
    ]
  end

  defp deps do
    version = File.read!(".file-version")
              |> String.trim()
              |> String.replace(".", "_")

    [
      # This is a non-Elixir dependency that we have Mix fetch.  We use this to
      # compile libmagic into our NIF's shared object.
      {:libmagic, github: "file/file", tag: "FILE#{version}", app: false, compile: false},

      # Development / testing dependencies
      {:dialyxir, "~> 0.5.1", only: :test},
      {:ex_doc, "~> 0.21.2", only: :docs},
    ]
  end
end


# Makefile tasks

defmodule Mix.Tasks.Compile.Make do
  @moduledoc "Compiles helper in c_src"

  def run(_args) do
    cond do
      match?({:win32, _}, :os.type()) ->
        exit(:not_supported)
      
      File.exists?(libmagic_library_path()) ->
        :noop
      
      true ->
        {result, _error_code} = System.cmd("make", [], stderr_to_stdout: true)
        Mix.shell.info(result)

        :ok
    end
  end

  def clean do
    {result, _error_code} = System.cmd("make", ["clean"], stderr_to_stdout: true)
    Mix.shell.info(result)

    :ok
  end

  defp libmagic_library_path do
    Path.join([Mix.Project.deps_path(), "libmagic", "src", ".libs", "libmagic.a"])
  end
end