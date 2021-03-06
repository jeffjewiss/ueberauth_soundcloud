defmodule Ueberauth.Strategy.Soundcloud.OAuth do
  @moduledoc """
  An implementation of OAuth2 for soundcloud.

  To add your `client_id` and `client_secret` include these values in your configuration.

      config :ueberauth, Ueberauth.Strategy.Soundcloud.OAuth,
        client_id: System.get_env("SOUNDCLOUD_CLIENT_ID"),
        client_secret: System.get_env("SOUNDCLOUD_CLIENT_SECRET")
  """
  use OAuth2.Strategy

  @defaults [
    strategy: __MODULE__,
    site: "https://api.soundcloud.com",
    authorize_url: "https://soundcloud.com/connect",
    token_url: "https://api.soundcloud.com/oauth2/token",
    token: %OAuth2.AccessToken{}
  ]

  @doc """
  Construct a client for requests to Soundcloud.

  Optionally include any OAuth2 options here to be merged with the defaults.

      Ueberauth.Strategy.Soundcloud.OAuth.client(redirect_uri: "http://127.0.0.1:4000/auth/soundcloud/callback")

  This will be setup automatically for you in `Ueberauth.Strategy.Soundcloud`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config = Keyword.merge(@defaults, Application.get_env(:ueberauth, Ueberauth.Strategy.Soundcloud.OAuth))
    opts = @defaults
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    client(opts)
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_token!(params \\ [], options \\ %{}) do
    headers = Dict.get(options, :headers, [])
    options = Dict.get(options, :options, [])
    client_options = Dict.get(options, :client_options, [])
    c = client(client_options)
    OAuth2.Client.get_token!(c, params, headers, options)
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
