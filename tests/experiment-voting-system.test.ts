import { describe, it, expect, beforeEach } from 'vitest';

// Simulated contract state
let voteCount = 0;
const experimentVotes = new Map();
const userVotes = new Map();
const tokenBalances = new Map();

// Simulated contract functions
function createVote(experimentId: number, proposer: string) {
  const voteId = ++voteCount;
  const startBlock = Date.now();
  experimentVotes.set(voteId, {
    experimentId,
    proposer,
    startBlock,
    endBlock: startBlock + 86400000, // 24 hours in milliseconds
    yesVotes: 0,
    noVotes: 0,
    status: "active"
  });
  return voteId;
}

function castVote(voteId: number, amount: number, voteType: string, voter: string) {
  const vote = experimentVotes.get(voteId);
  if (!vote) throw new Error('Invalid vote');
  if (Date.now() > vote.endBlock) throw new Error('Voting period ended');
  if (vote.status !== "active") throw new Error('Invalid vote status');
  if (voteType !== "yes" && voteType !== "no") throw new Error('Invalid vote type');
  const voterBalance = tokenBalances.get(voter) || 0;
  if (voterBalance < amount) throw new Error('Insufficient balance');
  
  // Burn tokens
  tokenBalances.set(voter, voterBalance - amount);
  
  // Record user vote
  userVotes.set(`${voteId}-${voter}`, { amount, vote: voteType });
  
  // Update vote counts
  if (voteType === "yes") {
    vote.yesVotes += amount;
  } else {
    vote.noVotes += amount;
  }
  experimentVotes.set(voteId, vote);
  return true;
}

function endVote(voteId: number) {
  const vote = experimentVotes.get(voteId);
  if (!vote) throw new Error('Invalid vote');
  if (Date.now() < vote.endBlock) throw new Error('Voting period not ended');
  if (vote.status !== "active") throw new Error('Invalid vote status');
  vote.status = vote.yesVotes > vote.noVotes ? "approved" : "rejected";
  experimentVotes.set(voteId, vote);
  return true;
}

// Helper function to set token balance
function setTokenBalance(account: string, balance: number) {
  tokenBalances.set(account, balance);
}

describe('Experiment Voting System Contract', () => {
  beforeEach(() => {
    voteCount = 0;
    experimentVotes.clear();
    userVotes.clear();
    tokenBalances.clear();
  });
  
  it('should create a new vote', () => {
    const id = createVote(1, 'scientist1');
    expect(id).toBe(1);
    const vote = experimentVotes.get(id);
    expect(vote.experimentId).toBe(1);
    expect(vote.status).toBe('active');
  });
  
  it('should allow casting votes', () => {
    const voteId = createVote(2, 'scientist2');
    setTokenBalance('voter1', 1000);
    setTokenBalance('voter2', 2000);
    expect(castVote(voteId, 500, "yes", 'voter1')).toBe(true);
    expect(castVote(voteId, 1000, "no", 'voter2')).toBe(true);
    const vote = experimentVotes.get(voteId);
    expect(vote.yesVotes).toBe(500);
    expect(vote.noVotes).toBe(1000);
  });
  
  it('should not allow voting with insufficient balance', () => {
    const voteId = createVote(3, 'scientist3');
    setTokenBalance('voter3', 100);
    expect(() => castVote(voteId, 200, "yes", 'voter3')).toThrow('Insufficient balance');
  });
  
  it('should end vote and determine result', () => {
    const voteId = createVote(4, 'scientist4');
    setTokenBalance('voter4', 3000);
    setTokenBalance('voter5', 2000);
    castVote(voteId, 3000, "yes", 'voter4');
    castVote(voteId, 2000, "no", 'voter5');
    
    // Fast-forward time
    const vote = experimentVotes.get(voteId);
    vote.endBlock = Date.now() - 1000; // Set end time to 1 second ago
    experimentVotes.set(voteId, vote);
    
    expect(endVote(voteId)).toBe(true);
    const endedVote = experimentVotes.get(voteId);
    expect(endedVote.status).toBe('approved');
  });
  
  it('should not allow voting after voting period', () => {
    const voteId = createVote(5, 'scientist5');
    setTokenBalance('voter6', 1000);
    
    // Fast-forward time
    const vote = experimentVotes.get(voteId);
    vote.endBlock = Date.now() - 1000; // Set end time to 1 second ago
    experimentVotes.set(voteId, vote);
    
    expect(() => castVote(voteId, 500, "yes", 'voter6')).toThrow('Voting period ended');
  });
  
  it('should not allow ending vote before voting period', () => {
    const voteId = createVote(6, 'scientist6');
    expect(() => endVote(voteId)).toThrow('Voting period not ended');
  });
});

