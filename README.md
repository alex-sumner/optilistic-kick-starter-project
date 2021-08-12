# optilistic-kick-starter-project
Smart contract and tests for a Kickstarter style crowdfunding scheme, requirements are part of a training exercise from https://optilistic.com/

Currently NFTHandler.sol, KickBronze.sol, KickSilver.sol and KickGold.sol are not used

Requirements:

- The smart contract is reusable; multiple projects can be registered and accept ETH concurrently.
- The goal is a preset amount of ETH.
  - This cannot be changed after a project gets created.
- Regarding contributing:
  - The contribute amount must be at least 0.01 ETH.
  - There is no upper limit.
  - Anyone can contribute to the project, including the creator.
  - One address can contribute as many times as they like.
- If the project is not fully funded within 30 days:
  - The project goal is considered to have failed
  - No one can contribute anymore
  - Supporters get their money back
- If the project is fully funded:
  - No one else can contribute (however, the last contribution can go over the goal)
  - The creator can withdraw any percentage of contributed funds
- The creator can choose to cancel their project before the 30 days are over

Additional Requirements (only first 2 implemented):

- Make funding timeout configurable.
- Add a configurable, timed spread of withdraw limits for the creator (i.e. can only withdraw 10% every X days).
- Add configurable support tiers, where a supporter receives a minted NFT of each tier they donate above. (not done yet)

Planned usage:

1. Owner creates contract specifying funding goal, time limit and draw down interval by calling KickFactory.launchProject. 
The new project is added to the factory contract's projects array.

2. Owner may cancel contract at any time until funds are drawn down.

3. Contributors may add funds until either deadline (creation time plus time limit) expires or goal is met or contract is cancelled, after any of these no further contributions may be made.

4. If contract cancelled or deadline expired and goal not met contributors can get their funds back by calling withdrawContribution

5. If goal is met and contract is not cancelled owner can withdraw the contributions in one or more transactions by calling drawDownFunds
