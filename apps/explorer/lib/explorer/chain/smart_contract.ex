defmodule Explorer.Chain.SmartContract do
  @moduledoc """
  The representation of a verified Smart Contract.

  "A contract in the sense of Solidity is a collection of code (its functions)
  and data (its state) that resides at a specific address on the Ethereum
  blockchain."
  http://solidity.readthedocs.io/en/v0.4.24/introduction-to-smart-contracts.html
  """

  alias Explorer.Chain.{Address, Hash}

  use Explorer.Schema

  @type t :: module

  schema "smart_contracts" do
    field(:name, :string)
    field(:compiler_version, :string)
    field(:optimization, :boolean)
    field(:contract_code, :string)
    field(:abi, {:array, :map})

    belongs_to(
      :address,
      Address,
      foreign_key: :address_hash,
      references: :hash,
      type: Hash.Truncated
    )

    timestamps()
  end

  def changeset(%__MODULE__{} = smart_contract, attrs) do
    smart_contract
    |> cast(attrs, [:name, :compiler_version, :optimization, :contract_code, :address_hash, :abi])
    |> validate_required([:name, :compiler_version, :optimization, :contract_code, :abi, :address_hash])
  end
end
