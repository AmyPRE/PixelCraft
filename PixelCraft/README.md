# PixelCraft 🎨

A decentralized platform for creating and minting procedurally generated pixel art NFTs on the Stacks blockchain.

## Overview

PixelCraft enables artists and developers to collaborate in creating unique pixel art through algorithmic generation. Artists can use registered algorithms to craft one-of-a-kind pixel art NFTs, while algorithm developers earn fees for their creative tools.

## Features

### 🎯 Core Functionality
- **Procedural Generation**: Create unique pixel art using deterministic algorithms with custom seeds
- **Algorithm Registry**: Developers can register their pixel art generation algorithms
- **NFT Minting**: Full SIP-009 compliant NFT implementation for pixel art pieces
- **Royalty System**: Built-in creator royalties (up to 10%) for secondary sales
- **Fee Distribution**: Automatic payment splitting between algorithm developers and platform

### 🔧 Smart Contract Functions

#### For Artists
- `craft-pixel-art`: Create a new pixel art NFT using an algorithm
- `transfer-pixel-art`: Transfer ownership of pixel art
- `get-artist-creation-count`: View total creations by artist
- `get-pixel-art-info`: Get detailed information about a pixel art piece

#### For Algorithm Developers
- `register-pixel-algorithm`: Register a new generation algorithm
- `get-algorithm-stats`: View usage statistics for algorithms
- `toggle-algorithm-status`: Enable/disable algorithm availability

#### Public Queries
- `get-pixel-owner`: Check current owner of a pixel art piece
- `get-pixel-art-uri`: Retrieve metadata URI for pixel art
- `get-pixel-algorithm`: Get algorithm details
- `get-platform-stats`: View platform-wide statistics

## Contract Architecture

### Data Structure
```clarity
;; Core NFT tracking
(define-non-fungible-token pixelcraft-nft uint)

;; Algorithm registry
(define-map pixel-algorithms (string-ascii 64) {
    developer: principal,
    algorithm-name: (string-ascii 64),
    algorithm-description: (string-ascii 256),
    generation-fee: uint,
    is-active: bool
})

;; Pixel art metadata
(define-map pixel-art-uri uint (string-ascii 256))
(define-map pixel-algorithm-key uint (string-ascii 64))
(define-map pixel-generation-seed uint uint)
```

### Economic Model
- Platform fee: 5% of algorithm usage fees (configurable by admin)
- Creator royalties: Up to 10% on secondary sales
- Algorithm developers set their own generation fees
- Automatic payment distribution on minting

## Usage Examples

### Register an Algorithm
```clarity
(register-pixel-algorithm 
    "retro-8bit" 
    "Retro 8-bit Style" 
    "Generates classic 8-bit pixel art with vintage color palettes" 
    u1000000) ;; 1 STX fee
```

### Craft Pixel Art
```clarity
(craft-pixel-art 
    "retro-8bit" 
    u12345      ;; Random seed
    "ipfs://..." ;; Metadata URI
    u250)       ;; 2.5% royalty
```

## Configuration

### Platform Settings
- **Max Supply**: 10,000 pixel art pieces (configurable)
- **Platform Fee**: 5% (500 basis points, max 20%)
- **Max Royalty**: 10% (1000 basis points)

## Security Features

- Algorithm availability controls
- Fee validation and limits
- Owner verification for transfers
- Supply cap enforcement
- Unauthorized access prevention

## Roadmap

- [ ] Multi-algorithm composition support
- [ ] Batch minting capabilities
- [ ] Enhanced metadata standards
- [ ] Cross-platform algorithm sharing
- [ ] Community governance features

## Contributing

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Submit a pull request
