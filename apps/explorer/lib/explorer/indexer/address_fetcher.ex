defmodule Explorer.Indexer.AddressFetcher do
  @moduledoc """
  Fetches and indexes `t:Explorer.Chain.Address.t/0`.
  """

  alias Explorer.Chain
  alias Explorer.Chain.{Hash, Address}

  @behaviour Explorer.Indexer.BufferedTask

  def async_fetch_balances(address_hashes) do
    string_hashes = for hash <- address_hashes, do: Hash.to_string(hash)
    Explorer.Indexer.BufferedTask.buffer(__MODULE__, string_hashes)
  end

  def init_stream(acc, reducer) do
    Chain.stream_unfetched_addresses(acc, fn %Address{hash: hash}, acc ->
      reducer.(Hash.to_string(hash), acc)
    end)
  end

  def run(string_hashes) do
    {:ok, results} = EthereumJSONRPC.fetch_balances_by_hash(string_hashes)
    :ok = Chain.update_balances(results)

    :ok
  end
end
