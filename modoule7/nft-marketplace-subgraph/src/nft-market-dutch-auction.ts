import { BigInt } from "@graphprotocol/graph-ts"
import {
  NFTMarketDutchAuction,
  AuctionCreated,
  AuctionSuccessful,
  AuctionCancelled
} from "../generated/NFTMarketDutchAuction/NFTMarketDutchAuction"
import { Auction, Purchase } from "../generated/schema"

export function handleAuctionCreated(event: AuctionCreated): void {
  let auction = new Auction(event.params.tokenId.toString())
  
  auction.tokenId = event.params.tokenId
  auction.seller = event.params.seller
  auction.startingPrice = event.params.startingPrice
  auction.endingPrice = event.params.endingPrice
  auction.duration = event.params.duration
  auction.startedAt = event.block.timestamp
  auction.createdAtTimestamp = event.block.timestamp
  auction.createdAtBlockNumber = event.block.number
  auction.cancelled = false
  auction.successful = false

  auction.save()
}

export function handleAuctionSuccessful(event: AuctionSuccessful): void {
  // Update auction
  let auction = Auction.load(event.params.tokenId.toString())
  if (auction != null) {
    auction.successful = true
    auction.save()
  }

  // Create purchase record
  let purchase = new Purchase(
    event.transaction.hash.concatI32(event.logIndex.toI32()).toHexString()
  )
  purchase.tokenId = event.params.tokenId
  purchase.buyer = event.params.winner
  purchase.price = event.params.totalPrice
  purchase.timestamp = event.block.timestamp
  purchase.blockNumber = event.block.number
  purchase.transactionHash = event.transaction.hash

  purchase.save()
}

export function handleAuctionCancelled(event: AuctionCancelled): void {
  let auction = Auction.load(event.params.tokenId.toString())
  if (auction != null) {
    auction.cancelled = true
    auction.save()
  }
}