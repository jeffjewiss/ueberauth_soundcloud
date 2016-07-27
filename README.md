# Überauth SoundCloud

> SoundCloud OAuth2 strategy for Überauth.
> Forked and adapted from Ueberauth's Github strategy: https://github.com/ueberauth/ueberauth_github

## Installation

1. Setup your application at [SoundCloud Developer](https://developer.soundcloud.com).

1. Add `:ueberauth_soundcloud` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:ueberauth_soundcloud, "~> 0.2"}]
    end
    ```

1. Add the strategy to your applications:

    ```elixir
    def application do
      [applications: [:ueberauth_soundcloud]]
    end
    ```

1. Add SoundCloud to your Überauth configuration:

    ```elixir
    config :ueberauth, Ueberauth,
      providers: [
        soundcloud: {Ueberauth.Strategy.Soundcloud, []}
      ]
    ```

1.  Update your provider configuration:

    ```elixir
    config :ueberauth, Ueberauth.Strategy.Soundcloud.OAuth,
      client_id: System.get_env("SOUNDCLOUD_CLIENT_ID"),
      client_secret: System.get_env("SOUNDCLOUD_CLIENT_SECRET"),
      redirect_uri: "http://127.0.0.1:4000/auth/soundcloud/callback", 
    ```
    *Quick note: SoundCloud has historically been grumpy about "localhost" addresses in the redirect_uri; if you have problems, try switching to "127.0.0.1" instead.*

1.  Include the Überauth plug in your controller:

    ```elixir
    defmodule MyApp.AuthController do
      use MyApp.Web, :controller
      plug Ueberauth
      ...
    end
    ```

1.  Create the request and callback routes if you haven't already:

    ```elixir
    scope "/auth", MyApp do
      pipe_through :browser

      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
    end
    ```

1. You controller needs to implement callbacks to deal with `Ueberauth.Auth` and `Ueberauth.Failure` responses.

For an example implementation see the [Überauth Example](https://soundcloud.com/ueberauth/ueberauth_example) application.

## Calling

Depending on the configured url you can initial the request through:

    /auth/soundcloud

Or with options:

    /auth/soundcloud?scope=email

By default scope is omitted; it doesn't seem to do anything... Scope can be configured either explicitly as a `scope` query value on the request path or in your configuration:

```elixir
config :ueberauth, Ueberauth,
  providers: [
    soundcloud: {Ueberauth.Strategy.Soundcloud, [default_scope: "email"]}
  ]
```

## License

Please see [LICENSE](https://soundcloud.com/ueberauth/ueberauth_soundcloud/blob/master/LICENSE) for licensing details.
