defmodule Ueberauth.Strategy.Soundcloud do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with Soundcloud.

  ### Setup

  Create an application in Soundcloud for you to use.

  Register a new application at: [your soundcloud developer page](https://soundcloud.com/you/apps) and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          soundcloud: { Ueberauth.Strategy.Soundcloud, [] }
        ]

  Then include the configuration for soundcloud.

      config :ueberauth, Ueberauth.Strategy.Soundcloud.OAuth,
        client_id: System.get_env("SOUNDCLOUD_CLIENT_ID"),
        client_secret: System.get_env("SOUNDCLOUD_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end

      scope "/auth" do
        pipe_through [:browser, :auth]

        get "/:provider/callback", AuthController, :callback
      end


  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller

        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end

        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.

  To set the `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          soundcloud: { Ueberauth.Strategy.Soundcloud, [uid_field: :email] }
        ]

  Default is `:id`

  Note: SoundCloud does nothing with the scope parameter (yet)
  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          soundcloud: { Ueberauth.Strategy.Soundcloud, [default_scope: "does_nothing"] }
        ]

  Deafult is "*"
  """
  use Ueberauth.Strategy, uid_field: :id,
                          default_scope: "*",
                          oauth2_module: Ueberauth.Strategy.Soundcloud.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the soundcloud authentication page.

  Note: SoundCloud does nothing with the scope parameter (yet)
  To customize the scope (permissions) that are requested by soundcloud include them as part of your url:

      "/auth/soundcloud?scope=does_nothing"

  You can also include a `state` param that soundcloud will return to you.
  """
  def handle_request!(conn) do
    # scopes = conn.params["scope"] || option(conn, :default_scope)
    # opts = [ scope: scopes ]
    opts = []
    # opts = Keyword.put(opts, :response_type, "code")
    if conn.params["state"], do: opts = Keyword.put(opts, :state, conn.params["state"])
    opts = Keyword.put(opts, :redirect_uri, callback_url(conn))
    module = option(conn, :oauth2_module)

    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from Soundcloud. When there is a failure from Soundcloud the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from Soundcloud is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{ params: %{ "code" => code } } = conn) do
    module = option(conn, :oauth2_module)
    token = apply(module, :get_token!, [[code: code]])

    if token.access_token == nil do
      set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    else
      fetch_user(conn, token)
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw Soundcloud response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:soundcloud_user, nil)
    |> put_private(:soundcloud_token, nil)
  end

  @doc """
  Fetches the uid field from the Soundcloud response. This defaults to the option `uid_field` which in-turn defaults to `login`
  """
  def uid(conn) do
    conn.private.soundcloud_user[option(conn, :uid_field) |> to_string]
  end

  @doc """
  Includes the credentials from the Soundcloud response.
  """
  def credentials(conn) do
    token = conn.private.soundcloud_token
    scopes = (token.other_params["scope"] || "")
    |> String.split(",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    user = conn.private.soundcloud_user

    %Info{
      name: user["full_name"],
      nickname: user["username"],
      location: user["country"],
      description: user["description"],
      image: user["avatar_url"],
      urls: %{
        uri: user["uri"],
        permalink_url: user["permalink_url"],
        avatar_url: user["avatar_url"],
        website: user["website"],
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the Soundcloud callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.soundcloud_token,
        user: conn.private.soundcloud_user
      }
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :soundcloud_token, token)
    case OAuth2.AccessToken.get(token, "/me", [], params: [oauth_token: token.access_token]) do
      { :ok, %OAuth2.Response{status_code: 401, body: _body}} ->
        set_errors!(conn, [error("token", "unauthorized")])
      { :ok, %OAuth2.Response{status_code: status_code, body: user} } when status_code in 200..399 ->
        put_private(conn, :soundcloud_user, user)
      { :error, %OAuth2.Error{reason: reason} } ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp option(conn, key) do
    Dict.get(options(conn), key, Dict.get(default_options, key))
  end
end
