defmodule JidoCartographer.ResultStoreTest do
  use ExUnit.Case, async: false

  alias JidoCartographer.ResultStore

  test "admits at most two active index jobs" do
    first = "first-#{System.unique_integer([:positive])}"
    second = "second-#{System.unique_integer([:positive])}"
    third = "third-#{System.unique_integer([:positive])}"

    assert :ok = ResultStore.create(first, %{})
    assert :ok = ResultStore.create(second, %{})
    assert {:error, :busy} = ResultStore.create(third, %{})

    assert :ok = ResultStore.complete(first, %{})
    assert :ok = ResultStore.complete(second, %{})
    assert :ok = ResultStore.create(third, %{})
    assert :ok = ResultStore.complete(third, %{})
  end
end
