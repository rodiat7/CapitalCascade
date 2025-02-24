# CapitalCascade

![CapitalCascade Logo](https://via.placeholder.com/200x200.png?text=CapitalCascade)

## Decentralized P2P Lending Protocol on Stacks

CapitalCascade is a decentralized peer-to-peer lending platform built on the Stacks blockchain that enables users to request, fund, and manage STX loans in a trustless environment.

## Overview

CapitalCascade creates a secure lending marketplace where:

- Borrowers can request loans by providing collateral
- Lenders can fund loan requests and earn interest
- Smart contracts manage loan terms, repayments, and liquidations
- All transactions are secured and verified on the Stacks blockchain

## Features

- **Collateralized Loans**: Borrowers deposit STX as collateral to secure their loans
- **Customizable Terms**: Configurable loan amounts, interest rates, durations, and payment frequencies
- **Automated Repayments**: Built-in payment scheduling and tracking
- **Liquidation Protection**: Automatic health checks maintain system solvency
- **Transparent Fees**: Clear penalty structure for late payments
- **Non-Custodial**: Funds are managed by smart contracts, not intermediaries

## How It Works

### For Borrowers

1. **Request a Loan**: Provide collateral and set loan terms
2. **Receive Funding**: Once a lender funds your request, receive the loan amount
3. **Make Payments**: Repay on schedule according to your payment frequency
4. **Retrieve Collateral**: When the loan is fully repaid, collateral is released

### For Lenders

1. **Browse Loan Requests**: Find opportunities matching your risk preferences
2. **Fund Loans**: Provide capital to borrowers and begin earning interest
3. **Collect Repayments**: Receive scheduled payments plus interest
4. **Liquidation Security**: If a loan's health ratio drops below threshold, claim the collateral

## Smart Contract Functions

### Core Functions

- `request-loan`: Create a new loan request with collateral
- `fund-loan`: Fund an existing loan request as a lender
- `make-payment`: Make a scheduled repayment on a loan
- `execute-liquidation`: Liquidate an undercollateralized loan

### Read-Only Functions

- `get-loan`: View details of a specific loan
- `get-payment-schedule`: Check repayment schedule for a loan
- `get-loan-health`: Calculate the current health ratio of a loan
- `should-liquidate`: Determine if a loan is eligible for liquidation

### Admin Functions

- `update-collateral-ratio`: Modify the required collateralization ratio
- `transfer-ownership`: Transfer platform administrative rights

## Technical Details

- **Contract Language**: Clarity
- **Blockchain**: Stacks
- **Collateralization Ratio**: 150% (configurable)
- **Liquidation Threshold**: 130%
- **Late Payment Fee**: 10% of payment amount

## Getting Started

### Prerequisites

- Stacks wallet (Hiro Wallet recommended)
- STX tokens for transactions, collateral, or lending

### Interacting with CapitalCascade

1. Connect your wallet to the CapitalCascade dApp
2. Browse available loans or create a loan request
3. Monitor your active positions in the dashboard

## Development

### Setting Up a Local Environment

```bash
# Clone the repository
git clone https://github.com/capitalcascade/protocol.git
cd protocol

# Install dependencies
npm install

# Run tests
npm test

# Deploy to testnet
npm run deploy:testnet
```

### Contract Deployment

The main contract can be deployed using Clarinet:

```bash
clarinet deploy
```

## Security

CapitalCascade's smart contracts have been thoroughly tested and audited for security vulnerabilities. However, users should exercise caution and understand the risks involved with decentralized finance.

- Risk of liquidation if collateral value drops
- Smart contract risk
- Market volatility risk

## Roadmap

- **Q2 2025**: Launch on Stacks Mainnet
- **Q3 2025**: Introduce multi-asset collateral options
- **Q4 2025**: Implement governance token and DAO
- **Q1 2026**: Add insurance pool for lenders

## Contributing

We welcome contributions from the community! Please see CONTRIBUTING.md for details.

