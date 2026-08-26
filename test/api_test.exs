defmodule JidoCartographer.APITest do
  use ExUnit.Case, async: false
  import Plug.Conn
  import Plug.Test

  alias JidoCartographer.API

  test "health reports the running service" do
    conn = conn(:get, "/health") |> API.call([])
    assert conn.status == 200

    assert Jason.decode!(conn.resp_body) == %{
             "ok" => true,
             "service" => "jido-cartographer",
             "version" => "0.1.0"
           }
  end

  test "index rejects an unsafe repository before starting work" do
    conn =
      conn(:post, "/api/index", Jason.encode!(%{url: "http://127.0.0.1/repo"}))
      |> put_req_header("content-type", "application/json")
      |> API.call([])

    assert conn.status == 400
    assert Jason.decode!(conn.resp_body)["error"] =~ "github.com"
  end

  test "unknown results and routes are explicit" do
    assert (conn(:get, "/api/results/missing") |> API.call([])).status == 404
    assert (conn(:get, "/missing") |> API.call([])).status == 404
  end
end
