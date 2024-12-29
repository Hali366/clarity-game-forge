import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test game creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('game-forge', 'create-game', [
        types.ascii("puzzle"),
        types.uint(4)
      ], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(0);
    
    let gameBlock = chain.mineBlock([
      Tx.contractCall('game-forge', 'get-game', [
        types.uint(0)
      ], deployer.address)
    ]);
    
    const gameData = gameBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(gameData['max-players'], types.uint(4));
    assertEquals(gameData['current-players'], types.uint(1));
  },
});

Clarinet.test({
  name: "Test game joining",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const player2 = accounts.get('wallet_1')!;
    
    // Create game
    let block = chain.mineBlock([
      Tx.contractCall('game-forge', 'create-game', [
        types.ascii("puzzle"),
        types.uint(4)
      ], deployer.address)
    ]);
    
    // Join game
    let joinBlock = chain.mineBlock([
      Tx.contractCall('game-forge', 'join-game', [
        types.uint(0)
      ], player2.address)
    ]);
    
    joinBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify player data
    let playerBlock = chain.mineBlock([
      Tx.contractCall('game-forge', 'get-player-data', [
        types.uint(0),
        types.principal(player2.address)
      ], deployer.address)
    ]);
    
    const playerData = playerBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(playerData['score'], types.uint(0));
  },
});

Clarinet.test({
  name: "Test move submission",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    // Create game
    chain.mineBlock([
      Tx.contractCall('game-forge', 'create-game', [
        types.ascii("puzzle"),
        types.uint(4)
      ], deployer.address)
    ]);
    
    // Make move
    let moveBlock = chain.mineBlock([
      Tx.contractCall('game-forge', 'make-move', [
        types.uint(0),
        types.uint(42)
      ], deployer.address)
    ]);
    
    moveBlock.receipts[0].result.expectOk().expectBool(true);
    
    // Verify move
    let playerBlock = chain.mineBlock([
      Tx.contractCall('game-forge', 'get-player-data', [
        types.uint(0),
        types.principal(deployer.address)
      ], deployer.address)
    ]);
    
    const playerData = playerBlock.receipts[0].result.expectOk().expectSome();
    assertEquals(playerData['last-move'], types.uint(42));
  },
});