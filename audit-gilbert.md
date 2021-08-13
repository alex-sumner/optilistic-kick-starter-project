The following is a micro audit of git commit 6351825cc4fd6dd7d4f15991cad7fee8978c29c9

## issue-1

**[Medium]** No goal minimum

In KickProject.sol:66, there is no validation on `_goal`. Consider validating `_goal` to be some positive multiple of the minimum contribution.

## issue-2

**[Code quality]** Unnecessary variable

In KickProject.sol:13, the `address public projectAddr` is not necessary as one cannot interact with the contract unless they know its address.

In KickFactory.sol:16, you can write `return address(project);`


## issue-3

**[Code quality]** Lack of events

Consider emitting events so offchain applications can listen for and respond to them.


## Nitpicks

- Commented out code indicatives that a codebase is not ready for an audit (but it doesn't matter here since we're in a course)
