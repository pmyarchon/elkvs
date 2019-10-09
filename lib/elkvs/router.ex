defmodule Router do
  use Plug.Router
  require Logger

  @param_key "key"
  @param_value "value"
  @param_ttl "ttl"

  plug Plug.Parsers, parsers: [:urlencoded]
  plug :match
  plug :dispatch

  # Create
  post "/" do
    {status, body} = case conn.params do
      %{@param_key => key, @param_value => value, @param_ttl => ttl} ->
        {s, b} = case Storage.create(key, value, String.to_integer(ttl)) do
          true -> {201, "Created"}
          false -> {400, "Already exists"}
        end

        Logger.debug("POST / {key = '#{key}', value = '#{value}', TTL = #{ttl}} -> #{s} #{b}")
        {s, b}

      _ ->
        {400, "Malformed request data"}
    end

    send_resp(conn, status, body)
  end

  # Read
  get "/:key" do
    {status, body} = case Storage.lookup(key) do
      nil -> {404, "Not found"}
      {_, value, _, _} -> {200, value}
      {:error, _reason} -> {500, "Internal server error"}
    end

    Logger.debug("GET /#{key} -> #{status} #{body}")
    send_resp(conn, status, body)
  end

  # Update
  put "/:key" do
    {status, body} = case conn.params do
      %{@param_value => value, @param_ttl => ttl} ->
        {s, b} = case Storage.update(key, value, String.to_integer(ttl)) do
          true -> {200, "OK"}
          false -> {404, "Not found"}
        end

        Logger.debug("PUT /#{key} {value = '#{value}', TTL = #{ttl}} -> #{s} #{b}")
        {s, b}

      _ ->
        {400, "Malformed request data"}
    end

    send_resp(conn, status, body)
  end

  # Delete
  delete "/:key" do
    {status, body} = case Storage.delete(key) do
      true -> {200, "OK"}
      false -> {404, "Not found"}
    end

    Logger.debug("DELETE /#{key} -> #{status} #{body}")
    send_resp(conn, status, body)
  end

  # Catch-up
  match _ do
    send_resp(conn, 404, "Not found")
  end
end
