# Audit by prolok

## Summary 
Good to see that you have covered all edge cases, and my eyes did not catch any high priority issues. I have some medium priority items, mostly around enforcing requirements. Code was mostly readable, apart from drawDownFunds/calcAmountAvailablenow, I think that whole design can be simplified.


## KickProject.sol

### High Priority

### Medium Priority
    1. Please ensure solidity > 0.8 so that arithmitic operations are carried out safely, use SafeMath otherwise.

    2. Line 127, Cancellation needs more checks, as per requirements cancellation is only allowed only until the deadline. In this case even after deadline is done, owner can cancel the project.

    3. Line 66, Goal minimum of 1 ether should be enforced.

        
### Low Priority
    1. Line 64 , Constructor should check if the value of owner is not 0
        https://github.com/crytic/slither/wiki/Detector-Documentation#missing-zero-address-validation

### Code Quality and Gas Optimizations
    1. There are too many state variables in KickProject, Some of them can be omitted with perhaps a different design and some are obvious like
        * projectAddress (Line 13) which is redundant and not required to be stored

    2 Good practice to log events. Following are example of events that can be emitted
        * event when project is cancelled
        * when a withdrawal happened
        * when a contribution happened

    3. public functions like cancel, withdrawContribution, drawdownfunds can be made external to save gas.
    



## ProjectFactory.sol

### High Priority

### Medium Priority

### Low Priority
    1. Line 13 and Line 19 can be made external instead of public.
    2. getProjects() function that returns all functions.

### Code Quality and Gas Optimizations

## testing

    ### Code Quality
        1. Nice to have isolated unit tests around factory and kickprojects separately.
        2. Once events are emitted, good to have tests around each events.
