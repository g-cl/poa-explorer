defmodule Explorer.SmartContract.Publisher do
  @moduledoc """
  Module responsible to control the contract verification.
  """

  alias Explorer.Chain
  alias Explorer.Chain.SmartContract
  alias Explorer.SmartContract.Verifier
  alias Ecto.Changeset

  def publish(address_hash, params) do
    case Verifier.evaluate_authenticity(address_hash, params) do
      {:ok, %{abi: abi}} ->
        publish_smart_contract(params, abi, address_hash)

      {:error, _} ->
        {:error, unverified_smart_contract(address_hash)}
    end
  end

  defp publish_smart_contract(params, abi, address_hash) do
    attrs = %{
      address_hash: address_hash,
      name: params["name"],
      compiler_version: params["compiler"],
      optimization: params["optimization"],
      contract_code: params["code"],
      abi: abi
    }

    Chain.create_smart_contract(attrs)
  end

  defp unverified_smart_contract(address_hash) do
    changeset =
      %SmartContract{address_hash: address_hash}
      |> SmartContract.changeset(%{})
      |> Changeset.add_error(:code, "there was an error validating your contract, please try again.")

    %{changeset | action: :insert}
  end
end
