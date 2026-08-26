defmodule JidoCartographer.API do
  use Plug.Router

  alias JidoCartographer.{Indexer, Repository, ResultStore}

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason)
  plug(:dispatch)

  get "/health" do
    json(conn, 200, %{ok: true, service: "jido-cartographer", version: "0.1.0"})
  end

  post "/api/index" do
    url = conn.body_params["url"]
    ref = conn.body_params["ref"]

    case Repository.parse(url, ref) do
      {:ok, _} ->
        id = Base.url_encode64(:crypto.strong_rand_bytes(12), padding: false)

        case ResultStore.create(id, %{url: url, ref: ref}) do
          :ok ->
            Task.Supervisor.start_child(JidoCartographer.JobSupervisor, fn ->
              ResultStore.running(id)

              case Indexer.index_with_timeout(url, ref) do
                {:ok, result} -> ResultStore.complete(id, result)
                {:error, reason} -> ResultStore.fail(id, reason)
              end
            end)

            json(conn, 202, %{id: id, status: "queued"})

          {:error, :busy} ->
            json(conn, 429, %{error: "indexer is busy; retry later"})
        end

      {:error, reason} ->
        json(conn, 400, %{error: reason})
    end
  end

  get "/api/results/:id" do
    case ResultStore.get(id) do
      {:ok, result} -> json(conn, 200, Map.put(result, :id, id))
      :error -> json(conn, 404, %{error: "result not found"})
    end
  end

  match _ do
    json(conn, 404, %{error: "not found"})
  end

  defp json(conn, status, body) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
  end
end
