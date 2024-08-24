// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract CrowdFunding {

    struct Campaign {
        string title;
        string description;
        address payable benefactor;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
    }

    mapping (address => Campaign) campaigns;
    mapping (address => bool) campaignExist;

    address[] public campaignIds;

    // validate if campaign goal is greater than zero
    modifier greaterThanZero(uint256 _goal) {
        require(_goal > 0, "Sorry campaign goal must be greater than zero.");
        _;
    }

    // validate 
    // 1. campaign actually exists
    // 2. campaign is still active
    modifier doubleCheck(address _benefactor) {
        Campaign memory campaign = campaigns[_benefactor];
        if(!campaignExist[_benefactor]) {
            revert("Sorry campaign does not exist.");
        } else if (block.timestamp >= campaign.deadline ) {
            revert("Sorry campaign has ended.");
        }
        _;
    }

    // validate who initialized the campaign
    modifier Owner(address _campaign, address _who) {
        Campaign memory campaign = campaigns[_campaign];
        require(campaign.benefactor != _who, "Wrong owner, access denied bitch!!!!!!!");
        _;
    }

    // designated events for 
    // 1. campaign creation
    // 2. donation to campaign
    // 3. campaign ending
    event campaignCreated(address _benefactor, string _description, uint256 _goal);
    event donationSuccessfull(address _sender, address _campaign, uint256 amount);
    event campaignEnded(address _campaign, uint256 amount);

    // create campaign with required fields validated by greater than modifier
    function createCampaign(
        string memory _title, 
        string memory _description, 
        address payable _benefactor, 
        uint256 _goal, 
        uint256 _deadline
    ) public greaterThanZero(_goal)
    {
        Campaign memory data = Campaign({
            title: _title,
            description: _description,
            benefactor: _benefactor,
            goal: _goal,
            deadline: _deadline,
            amountRaised: 0
        });

        campaigns[_benefactor] = data;
        campaignExist[_benefactor] = true;
        campaignIds.push(_benefactor);
        emit campaignCreated(_benefactor, _description, _goal);
    }

    // donate to campaign validated by double check modifier
    function donateToCampaign(address payable _benefactor) public doubleCheck(_benefactor) payable {
        Campaign storage campaign = campaigns[_benefactor];
        campaign.goal += msg.value;
        emit donationSuccessfull(msg.sender, _benefactor, msg.value);
    }

    // end campaing and withdraw amount to campaign owner address validated by Owner modifier
    function endCampaign(address payable _campaign, address payable _who) public Owner(_campaign, _who)  {
        Campaign storage campaign = campaigns[_campaign];

        if(block.timestamp >= campaign.deadline) {
            (bool success,) = campaign.benefactor.call{value: campaign.goal}("");
            require(success, "Failed to send Ether");
            emit campaignEnded(_campaign, campaign.goal);
        } else {
            revert("Campaign is still active.");
        }
    
    }

    // withdraw from campaign and withdraw amount to campaign owner address validated by Owner modifier
    function withDraw(address payable _campaign, address payable _who) public Owner(_campaign, _who)  {
        Campaign storage campaign = campaigns[_campaign];

        if(block.timestamp >= campaign.deadline) {
            (bool success,) = campaign.benefactor.call{value: campaign.goal}("");
            require(success, "Failed to send Ether");
            emit campaignEnded(_campaign, campaign.goal);
        } else {
            revert("Campaign is still active.");
        }
    
    }

    // get campaing balance validated by Owner modifier
    function getBalance(address _campaign, address _who) public Owner(_campaign, _who) view returns(uint256) {
        Campaign storage campaign = campaigns[_campaign];
        return campaign.goal;
    }

    // fetch list of created campaign adddresses
    function getCampaigns() public view returns (address[] memory) {
        return campaignIds;
    }
 
}
