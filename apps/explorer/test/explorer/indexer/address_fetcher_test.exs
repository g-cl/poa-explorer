defmodule Explorer.Indexer.AddressFetcherTest do
  # MUST be `async: false` so that {:shared, pid} is set for connection to allow AddressFetcher's self-send to have
  # connection allowed immediately.
  use Explorer.DataCase, async: false

  alias Explorer.Chain.Address
  alias Explorer.Indexer.AddressFetcher

  @hash %Explorer.Chain.Hash{
    byte_count: 20,
    bytes: <<139, 243, 141, 71, 100, 146, 144, 100, 242, 212, 211, 165, 101, 32, 167, 106, 179, 223, 65, 91>>
  }

  setup do
    start_supervised!({Task.Supervisor, name: Explorer.Indexer.TaskSupervisor})

    :ok
  end

  describe "init/1" do
    test "fetches unfetched addresses" do
      unfetched_address = insert(:address, hash: @hash)

      assert unfetched_address.fetched_balance == nil
      assert unfetched_address.balance_fetched_at == nil

      start_address_fetcher()

      fetched_address =
        wait(fn ->
          Repo.one!(from(address in Address, where: address.hash == ^@hash and not is_nil(address.fetched_balance)))
        end)

      refute fetched_address.balance_fetched_at == nil
    end

    test "fetches unfetched addresses when less than max batch size" do
      insert(:address, hash: @hash)

      start_address_fetcher(max_batch_size: 2)

      fetched_address =
        wait(fn ->
          Repo.one!(from(address in Address, where: address.hash == ^@hash and not is_nil(address.fetched_balance)))
        end)

      refute fetched_address.balance_fetched_at == nil
    end
  end

  describe "async_fetch_balances/1" do
    test "fetches balances for address_hashes" do
      start_address_fetcher()

      assert :ok = AddressFetcher.async_fetch_balances([@hash])

      address =
        wait(fn ->
          Repo.get!(Address, @hash)
        end)

      refute address.fetched_balance == nil
    end
  end

  defp start_address_fetcher(options \\ []) when is_list(options) do
    start_supervised!(
      {AddressFetcher,
       Keyword.merge(
         [debug_logs: false, fetch_interval: 1, max_batch_size: 1, max_concurrency: 1],
         options
       )}
    )
  end

  defp wait(producer) do
    producer.()
  rescue
    Ecto.NoResultsError ->
      Process.sleep(100)
      wait(producer)
  end
end
