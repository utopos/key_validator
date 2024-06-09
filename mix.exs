defmodule KeyValidator.MixProject do
  use Mix.Project

  def project do
    [
      app: :key_validator,
      version: "0.1.0",
      elixir: "~> 1.16.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      # Docs
      name: "KeyValidator",
      description:
        "Compile-time validation to assure all the map/keyword keys exist in the target struct. Use case: maps that will be merged with structs.",
      package: package(),
      source_url: "https://github.com/utopos/key_validator",
      docs: [
        # The main page in the docs
        main: "KeyValidator"
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  def package() do
    [
      maintainers: ["Jakub Lambrych"],
      licenses: ["MIT"],
      links: %{
        GitHub: "https://github.com/utopos/key_validator"
      }
    ]
  end
end
