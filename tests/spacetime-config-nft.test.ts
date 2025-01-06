import { describe, it, expect, beforeEach } from 'vitest';

// Simulated contract state
let lastTokenId = 0;
const tokenMetadata = new Map();
const tokenOwners = new Map();

// Simulated contract functions
function mintSpacetimeConfig(configType: string, description: string, complexity: number, stability: number, dimensions: number, creator: string) {
  const tokenId = ++lastTokenId;
  if (stability < 0 || stability > 100 || complexity < 0 || complexity > 100 || dimensions < 1 || dimensions > 11) {
    throw new Error('Invalid parameters');
  }
  tokenMetadata.set(tokenId, {
    creator,
    configType,
    description,
    complexity,
    stability,
    dimensions,
    creationTime: Date.now()
  });
  tokenOwners.set(tokenId, creator);
  return tokenId;
}

function transferSpacetimeConfig(tokenId: number, sender: string, recipient: string) {
  if (tokenOwners.get(tokenId) !== sender) {
    throw new Error('Not authorized');
  }
  tokenOwners.set(tokenId, recipient);
  return true;
}

describe('Spacetime Configuration NFT Contract', () => {
  beforeEach(() => {
    lastTokenId = 0;
    tokenMetadata.clear();
    tokenOwners.clear();
  });
  
  it('should mint a new spacetime configuration NFT', () => {
    const id = mintSpacetimeConfig('Hyperbolic Manifold', 'Non-Euclidean spacetime with negative curvature', 85, 70, 4, 'scientist1');
    expect(id).toBe(1);
    const metadata = tokenMetadata.get(id);
    expect(metadata.configType).toBe('Hyperbolic Manifold');
    expect(metadata.dimensions).toBe(4);
    expect(tokenOwners.get(id)).toBe('scientist1');
  });
  
  it('should transfer spacetime configuration NFT ownership', () => {
    const id = mintSpacetimeConfig('Calabi-Yau Manifold', 'Compact complex manifold for string theory', 95, 60, 10, 'scientist2');
    expect(transferSpacetimeConfig(id, 'scientist2', 'researcher1')).toBe(true);
    expect(tokenOwners.get(id)).toBe('researcher1');
  });
  
  it('should not allow minting with invalid parameters', () => {
    expect(() => mintSpacetimeConfig('Invalid Config', 'This should fail', 101, 50, 3, 'scientist3')).toThrow('Invalid parameters');
    expect(() => mintSpacetimeConfig('Another Invalid', 'This should also fail', 80, 110, 12, 'scientist4')).toThrow('Invalid parameters');
  });
  
  it('should not allow unauthorized transfers', () => {
    const id = mintSpacetimeConfig('AdS/CFT Correspondence', 'Holographic principle implementation', 90, 75, 5, 'scientist5');
    expect(() => transferSpacetimeConfig(id, 'unauthorized_user', 'researcher2')).toThrow('Not authorized');
  });
  
  it('should allow minting of various dimensional configurations', () => {
    const id1 = mintSpacetimeConfig('2D Flatland', 'Two-dimensional universe model', 30, 95, 2, 'scientist6');
    const id2 = mintSpacetimeConfig('11D M-theory', 'Eleven-dimensional supergravity', 100, 40, 11, 'scientist7');
    expect(tokenMetadata.get(id1).dimensions).toBe(2);
    expect(tokenMetadata.get(id2).dimensions).toBe(11);
  });
});

