defmodule Explorer.Repo.Migrations.AddInternalTransactionsFetchedAtToTransactions do
  use Ecto.Migration

  def change do
    alter table(:transactions) do
      add(:internal_transactions_indexed_at, :utc_datetime)
    end
  end
end
