## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

# BuggySafe Contract - Funds Stuck Bug

## Overview

The `BuggySafe` contract contains a critical bug that causes funds to become permanently stuck in the contract, making them inaccessible to users.

## The Bug

The bug is in the `withdraw()` function:

```solidity
function withdraw() public {
    require(owner == msg.sender, "Only Owner can Withdraw");
    require(balance > 0, "No funds to withdraw");
    
    // BUG: The balance variable is decremented BEFORE sending the ETH
    // This means if the ETH transfer fails, the balance is already reduced
    // Also, the balance is reduced by the full amount, not the actual amount sent
    balance = 0; // This should be after successful transfer
    
    (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
    require(success, "Transfer failed");
    
    // The balance is already 0, so even if there are remaining funds,
    // they cannot be withdrawn because balance == 0
}
```

### What Happens

1. **Balance is set to 0 before transfer**: The `balance = 0` line executes before the ETH transfer
2. **Transfer sends current balance**: The transfer uses `address(this).balance` which may be different from the tracked `balance` variable
3. **Funds become stuck**: If the transfer doesn't send all ETH, the remaining funds become inaccessible because `balance == 0`
4. **No way to recover**: Once `balance` is 0, no more withdrawals can be made, even if ETH remains in the contract

## Running the Tests

### Prerequisites

Make sure you have Foundry installed. If not, install it with:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Install Dependencies

```bash
forge install foundry-rs/forge-std
```

### Run Tests

```bash
# Run all tests
forge test

# Run with verbose output
forge test -vv

# Run with very verbose output (shows logs)
forge test -vvv

# Run a specific test
forge test --match-test testFundsGetStuckAfterWithdrawal
```

## Test Cases

The test suite demonstrates several scenarios where funds become stuck:

1. **`testFundsGetStuckAfterWithdrawal`**: Shows basic stuck funds scenario
2. **`testMultipleDepositsCreateStuckFunds`**: Demonstrates how multiple deposits create stuck funds
3. **`testCompleteStuckFundsScenario`**: Integration test showing the complete bug
4. **`testBugAffectsAllUsers`**: Shows how the bug affects different users
5. **`testExactBugMechanism`**: Traces the exact mechanism of the bug
6. **`testFundsBecomePermanentlyInaccessible`**: Shows how funds become permanently inaccessible

## Expected Test Results

All tests should pass, demonstrating that:

- Funds get stuck in the contract after withdrawal
- The `balance` variable becomes 0, preventing further withdrawals
- The contract still contains ETH that cannot be accessed
- This creates a permanent loss of funds

## How to Fix

The bug can be fixed by:

1. **Moving the balance update after successful transfer**:
```solidity
(bool success,) = payable(msg.sender).call{value: balance}("");
require(success, "Transfer failed");
balance = 0; // Move this line here
```

2. **Using the tracked balance for transfers**:
```solidity
(uint256 amountToSend,) = payable(msg.sender).call{value: balance}("");
```

3. **Adding proper error handling** to ensure state consistency

## Security Impact

This bug represents a **high severity** vulnerability because:
- It causes permanent loss of user funds
- It affects the core functionality of the contract
- It can be triggered by normal user operations
- There is no way to recover the stuck funds
