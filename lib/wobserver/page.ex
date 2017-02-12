defmodule Wobserver.Page do
  @moduledoc """
  Page management for custom commands and pages in api and wobserver.
  """

  alias Wobserver.Page

  @pages_table :wobserver_pages

  @typedoc ~S"""
  Accepted page formats.
  """
  @type data ::
    Page.t
    | map
    | {String.t, atom, fun}
    | {String.t, atom, fun, boolean}

  @typedoc ~S"""
  Page structure.

  Fields:
    - `title`, the name of the page. Is used for the web interface menu.
    - `command`, single atom to associate the page with.
    - `callback`, function to be evaluated, when the a api is called or page is viewd.
                  The result is converted to JSON and displayed.
    - `options`, map containing options for the page.

  Options:
    - `api_only` (`boolean`), if set to true the page won't show up in the web interface, but will only be available as API.
    - `refresh` (`float`, 0-1), sets the refresh time factor. Used in the web interface to refresh the data on the page. Set to `0` for no refresh.
  """
  @type t :: %__MODULE__{
    title: String.t,
    command: atom,
    callback: fun,
    options: keyword,
  }

  defstruct [
    :title,
    :command,
    :callback,
    options: %{
      api_only: false,
      refresh: 1,
    },
  ]

  @doc ~S"""
  List all registered pages.

  For every page the following information is given:
    - `title`
    - `command`
    - `api_only`
    - `refresh`
  """
  @spec list :: list(map)
  def list do
    ensure_table()

    @pages_table
    |> :ets.match(:"$1")
    |> Enum.map(fn [{command, %Page{title: title, options: options}}] ->
         %{
           title: title,
           command: command,
           api_only: options.api_only,
           refresh: options.refresh,
          }
       end)
  end

  @doc ~S"""
  Find the page for a given command.

  Returns `:page_not_found`, if no page can be found.
  """
  @spec find(command :: atom) :: Page.t
  def find(command) do
    ensure_table()

    case :ets.lookup(@pages_table, command) do
      [{^command, page}] -> page
      _ -> :page_not_found
    end
  end

  @doc ~S"""
  Calls the function associated with the command/page.

  Returns the result of the function or `:page_not_found`, if the page can not be found.
  """
  @spec call(Page.t | atom) :: any
  def call(:page_not_found), do: :page_not_found
  def call(%Page{callback: callback}), do: callback.()
  def call(command) when is_atom(command), do: command |> find() |> call()
  def call(_), do: :page_not_found

  @doc ~S"""
  Registers a page with `:wobserver`.

  Returns true if succesfully added. (otherwise false)

  The following inputs are accepted:
    - `{title, command, callback}`
    - `{title, command, callback, options}`
    - a `map` with the following fields:
        - `title`
        - `command`
        - `callback`
        - `options` (optional)

  The fields are used as followed:
    - `title`, the name of the page. Is used for the web interface menu.
    - `command`, single atom to associate the page with.
    - `callback`, function to be evaluated, when the a api is called or page is viewd.
                  The result is converted to JSON and displayed.
    - `options`, options for the page.

  The following options can be set:
    - `api_only` (`boolean`), if set to true the page won't show up in the web interface, but will only be available as API.
    - `refresh` (`float`, 0-1), sets the refresh time factor. Used in the web interface to refresh the data on the page. Set to `0` for no refresh.
  """
  @spec register(page :: Page.data) :: boolean
  def register(page)

  def register({title, command, callback}),
    do: register(title, command, callback)
  def register({title, command, callback, options}),
    do: register(title, command, callback, options)

  def register(page = %Page{}) do
    ensure_table()
    :ets.insert @pages_table, {page.command, page}
  end

  def register(%{title: t, command: command, callback: call, options: options}),
    do: register(t, command, call, options)
  def register(%{title: title, command: command, callback: callback}),
    do: register(title, command, callback)
  def register(_), do: false

  @doc ~S"""
  Registers a page with `:wobserver`.

  For more information and types see: `Wobserver.Page.register/1`.
  """
  @spec register(
    title :: String.t,
    command :: atom,
    callback :: fun,
    options :: keyword
  ) :: boolean
  def register(title, command, callback, options \\ []) do
    register(%Page{
      title: title,
      command: command,
      callback: callback,
      options: %{
        api_only: Keyword.get(options, :api_only, false),
        refresh: Keyword.get(options, :refresh, 1.0)
      },
    })
  end

  @doc ~S"""
  Loads custom pages from configuration and adds them to `:wobserver`.

  To add custom pages set the `:pages` option.
  The `:pages` option must be a list of page data.

  The page data can be formatted as:
    - `{title, command, callback}`
    - `{title, command, callback, options}`
    - a `map` with the following fields:
        - `title`
        - `command`
        - `callback`
        - `options` (optional)

  For more information and types see: `Wobserver.Page.register/1`.

  Example:
  ```elixir
  config :wobserver,
    pages: [
      {"Example", :example, fn -> %{x:  9} end}
    ]
  ```
  """
  @spec load_config :: [any]
  def load_config do
    ensure_table()

    :wobserver
    |> Application.get_env(:pages, [])
    |> Enum.map(&register/1)
  end

  # Helpers

  defp ensure_table do
    case :ets.info(@pages_table) do
      :undefined ->
        :ets.new @pages_table, [:named_table, :public]
        true
      _ ->
        true
    end
  end
end
