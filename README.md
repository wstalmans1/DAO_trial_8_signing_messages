# DApp Setup (Rookie-friendly)

**Frontend**: Vite + React 18 + RainbowKit v2 + wagmi v2 + viem + TanStack Query v5 + Tailwind v4  
**Contracts**: Hardhat v2 + @nomicfoundation/hardhat-toolbox (ethers v6), OpenZeppelin, TypeChain, hardhat-deploy  
**DX**: Foundry (Forge/Anvil), gas-reporter, contract-sizer, solidity-docgen (auto, opt-out), Solhint/Prettier, Husky  
**Documentation**: Comprehensive NatSpec support with linting, validation, and auto-generation (disable with `DOCS_AUTOGEN=false`)  
**CI**: GitHub Actions

## 1) First-time setup
```bash
bash setup.sh
```

Fill envs:

* `apps/dao-dapp/.env.local`: `VITE_WALLETCONNECT_ID`, RPCs
* `packages/contracts/.env.hardhat.local`: `PRIVATE_KEY` or `MNEMONIC`, RPCs, `ETHERSCAN_API_KEY`, optional `CMC_API_KEY`

Optional speedups:

```bash
pnpm approve-builds
# select: bufferutil, utf-8-validate, keccak, secp256k1
```

## 2) Everyday commands

Frontend:

```bash
pnpm web:dev
```

Local chain:

```bash
pnpm anvil:start   # stop: pnpm anvil:stop
```

Contracts (Hardhat):

```bash
pnpm contracts:compile
pnpm contracts:test
pnpm contracts:deploy
pnpm contracts:verify
pnpm contracts:verify:multi   # Try both Etherscan and Blockscout
pnpm contracts:verify:stdjson # Verify via standard JSON input
pnpm contracts:debug          # Inspect code size and balance for an address
pnpm contracts:deploy-upgradeable # Deploy an upgradeable proxy
pnpm contracts:upgrade        # Upgrade an existing proxy
pnpm contracts:verify-upgradeable # Verify upgradeable proxy/impl
pnpm contracts:docs          # Generate Markdown docs from NatSpec (solidity-docgen)
pnpm contracts:lint:natspec  # Lint NatSpec documentation
```

Contracts (Foundry):

```bash
pnpm forge:test
pnpm forge:fmt
pnpm foundry:update
```

## 3) Example contract (OpenZeppelin)

Create `packages/contracts/contracts/MyToken.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MyToken is ERC20 {
  constructor() ERC20("MyToken","MTK") { _mint(msg.sender, 1_000_000 ether); }
}
```

Deploy (create `packages/contracts/deploy/01_mytoken.ts`):

```ts
import type { DeployFunction } from 'hardhat-deploy/types'
const func: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = deployments; const { deployer } = await getNamedAccounts();
  await deploy('MyToken', { from: deployer, args: [], log: true });
}
export default func; func.tags = ['MyToken'];
```

Run:

```bash
pnpm contracts:compile
pnpm --filter contracts exec hardhat deploy --network sepolia --tags MyToken
```

Artifacts (ABIs) appear in `apps/dao-dapp/src/contracts/`.

## 4) NatSpec Documentation

This setup includes comprehensive NatSpec support:

### Features:
- **NatSpec Linting**: Solhint rules enforce proper documentation format
- **Docs on Demand**: Generate lightweight Markdown docs without Vue dependencies
- **Auto-generation**: Docs refresh after each compile; set `DOCS_AUTOGEN=false` to skip
- **Validation**: NatSpec comments are validated during development
- **Formatting**: Prettier ensures consistent NatSpec formatting

### Commands:
```bash
pnpm contracts:docs          # Generate Markdown documentation into packages/contracts/docs
pnpm contracts:lint:natspec  # Check NatSpec compliance
```

### NatSpec Tags Supported:
- `@title` - Contract/function title
- `@notice` - User-facing description
- `@dev` - Developer notes
- `@param` - Parameter descriptions
- `@return` - Return value descriptions
- `@author` - Author information
- `@custom:*` - Custom tags

### Example:
See `packages/contracts/contracts/ExampleToken.sol` for a comprehensive example.

Documentation is written to `packages/contracts/docs` after every compile unless `DOCS_AUTOGEN=false`, or on demand via `pnpm contracts:docs`.

NatSpec comments are validated and formatted, ready for documentation generation with tools like:
- `solidity-docgen` - Default Hardhat-integrated generator (Markdown)
- `docusaurus` - Full documentation site generator
