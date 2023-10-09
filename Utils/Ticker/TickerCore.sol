pragma solidity ^0.8.0;

interface ActivityContract {
    function execute(address user, uint8 tier) external;
}

contract TickerCore {
    struct ActiveUser {
        uint8 skillId;
        uint8 tier;
        bool active;
    }

    mapping(uint => address) public skills;
    mapping(address => ActiveUser) public activeUsers;

    // Batch management
    uint public constant BATCH_SIZE = 100;
    mapping(uint => address[]) public batches;

    function addSkill(uint skillId, address skillContract) external {
        // TODO: Add permission checks
        skills[skillId] = skillContract;
    }

    function startActivity(uint8 skillId, uint8 tier, uint batchId) external {
        require(!activeUsers[msg.sender].active, "Already in an activity");
        require(skills[skillId] != address(0), "Invalid skill");
        require(batches[batchId].length < BATCH_SIZE, "Batch is full");
        
        activeUsers[msg.sender] = ActiveUser({
            skillId: skillId,
            tier: tier,
            active: true
        });
        
        batches[batchId].push(msg.sender);
    }

    function tick(uint batchId) external {
        address[] storage batch = batches[batchId];
        
        for (uint i = 0; i < batch.length; i++) {
            address userAddress = batch[i];
            ActiveUser storage user = activeUsers[userAddress];
            
            if (user.active) {
                ActivityContract(skills[user.skillId]).execute(userAddress, user.tier);
                // TODO: Add logic to handle user's state after tick, e.g., remove from batch if activity completed
            }
        }
    }

    // TODO: Add functions to stop activity, remove skill, etc.
}