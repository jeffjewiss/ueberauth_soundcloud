defmodule UeberauthSoundcloud.Mixfile do
  use Mix.Project

  @version "0.0.1"

  def project do
    [app: :ueberauth_soundcloud,
     version: @version,
     name: "Ueberauth Soundcloud",
     package: package,
     elixir: "~> 1.1",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://soundcloud.com/superpersonman/ueberauth_soundcloud",
     homepage_url: "https://soundcloud.com/superpersonman/ueberauth_soundcloud",
     description: description,
     deps: deps,
     docs: docs]
  end

  def application do
    [applications: [:logger, :ueberauth, :oauth2]]
  end

  defp deps do
    [{:ueberauth, "~> 0.2"},
     {:oauth2, "~> 0.5"},

     # docs dependencies
     {:earmark, "~>0.1", only: :dev},
     {:ex_doc, "~>0.1", only: :dev}]
  end

  defp docs do
    [extras: docs_extras, main: "extra-readme"]
  end

  defp docs_extras do
    ["README.md"]
  end

  defp description do
    "An Ueberauth strategy for using SoundCloud to authenticate your users."
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Dustin M. Chaffin"],
      licenses: ["MIT"],
      links: %{"SoundCloud": "https://soundcloud.com/superpersonman/ueberauth_soundcloud"}]
  end
end
