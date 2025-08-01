import { BigInt } from "@graphprotocol/graph-ts"
import {
  MyCollectible,
  Approval,
  ApprovalForAll,
  Transfer
} from "../generated/MyCollectible/MyCollectible"
import { NFT, Approval as ApprovalEntity, ApprovalForAll as ApprovalForAllEntity, Transfer as TransferEntity } from "../generated/schema"

export function handleApproval(event: Approval): void {
  let entity = new ApprovalEntity(
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  entity.owner = event.params.owner
  entity.approved = event.params.approved
  entity.tokenId = event.params.tokenId
  entity.timestamp = event.block.timestamp
  entity.blockNumber = event.block.number
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleApprovalForAll(event: ApprovalForAll): void {
  let entity = new ApprovalForAllEntity(
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  entity.owner = event.params.owner
  entity.operator = event.params.operator
  entity.approved = event.params.approved
  entity.timestamp = event.block.timestamp
  entity.blockNumber = event.block.number
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleTransfer(event: Transfer): void {
  // Create or update NFT entity
  let nft = NFT.load(event.params.tokenId.toString())
  if (nft == null) {
    nft = new NFT(event.params.tokenId.toString())
    nft.tokenId = event.params.tokenId
    nft.createdAtTimestamp = event.block.timestamp
    nft.createdAtBlockNumber = event.block.number
  }
  
  nft.owner = event.params.to
  
  // Try to get tokenURI
  let contract = MyCollectible.bind(event.address)
  let tokenURIResult = contract.try_tokenURI(event.params.tokenId)
  if (!tokenURIResult.reverted) {
    nft.tokenURI = tokenURIResult.value
  }
  
  nft.save()

  // Create Transfer entity
  let transfer = new TransferEntity(
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  transfer.from = event.params.from
  transfer.to = event.params.to
  transfer.tokenId = event.params.tokenId
  transfer.timestamp = event.block.timestamp
  transfer.blockNumber = event.block.number
  transfer.transactionHash = event.transaction.hash

  transfer.save()
}