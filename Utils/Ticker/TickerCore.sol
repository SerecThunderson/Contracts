pragma solidity ^0.8.0;

interface ActivityContract {
    function execute(address user, uint8 tier) external;
}

contract TickerCore {
    struct ActiveUser {
        uint8 skillId;
        uint8 tier;
        bool active;
        uint batchId;
    }

    mapping(uint => address) public skills;
    mapping(address => ActiveUser) public activeUsers;
    mapping(address => uint) public userBatchIndex;

    uint public constant BATCH_SIZE = 100;
    mapping(uint => address[]) public batches;

    modifier onlyActivityContract() {
        require(skills[uint(msg.sender)] != address(0), "Caller is not an authorized ActivityContract");
        _;
    }

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
            active: true,
            batchId: batchId
        });

        batches[batchId].push(msg.sender);
        userBatchIndex[msg.sender] = batches[batchId].length - 1;
    }

    function tick(uint batchId) external {
        address[] storage batch = batches[batchId];
        
        for (uint i = 0; i < batch.length; i++) {
            address userAddress = batch[i];
            ActiveUser storage user = activeUsers[userAddress];
            
            if (user.active) {
                ActivityContract(skills[user.skillId]).execute(userAddress, user.tier);
            }
        }
    }

    function finishActivity(address userAddress) external onlyActivityContract {
        ActiveUser storage user = activeUsers[userAddress];
        require(user.active, "User is not active");

        address[] storage batch = batches[user.batchId];
        uint index = userBatchIndex[userAddress];
        batch[index] = batch[batch.length - 1];
        userBatchIndex[batch[batch.length - 1]] = index;
        batch.pop();

        user.active = false;
	user.batchId = 0;
    }

    // TODO: Add functions to stop activity, remove skill, etc.
}
