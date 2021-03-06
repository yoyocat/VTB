pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./VTBToken.sol";

contract VTBCrowdfund is Ownable {

    using SafeMath for uint;

    address public tokenAddress;                          // Address of the deployed VTB token contract
    address public wallet;                                // Address of secure wallet to receive crowdfund contributions

    uint256 public weiRaised = 0;
    uint256 public startsAt;                              // Crowdfund starting time (Epoch format)
    uint256 public endsAt;                                // Crowdfund ending time (Epoch format)

    VTBToken public VTB;                                  // Instance of the VTB token contract

/*----------------- Events -----------------*/

    event WalletAddressChanged(address _wallet);           // Triggered upon owner changing the wallet address
    event AmountRaised(address beneficiary, uint amountRaised); // Triggered upon crowdfund being finalized
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount); // Triggered upon purchasing tokens

/*----------------- Modifiers -----------------*/

    modifier nonZeroAddress(address _to) {                 // Ensures an address is provided
        require(_to != 0x0);
        _;
    }

    modifier nonZeroValue() {                              // Ensures a non-zero value is passed
        require(msg.value > 0);
        _;
    }

    modifier crowdfundIsActive() {                         // Ensures the crowdfund is ongoing
        require(now >= startsAt && now <= endsAt);
        _;
    }

    modifier notBeforeCrowdfundEnds(){                     // Ensures actions can only happen after crowdfund ends
        require(now >= endsAt);
        _;
    }


/*----------------- Crowdfunding API -----------------*/

    // -------------------------------------------------
    // Contract's constructor
    // -------------------------------------------------
    function VTBCrowdfund(address _tokenAddress) public {
        wallet       = 0x0;                                // ICO wallet address
        startsAt     = 1522029600;                         // Mar 26th 2018, 10:00, GMT+8
        endsAt       = 1585188000;                         // Mar 26th 2020, 10:00, GMT+8
        tokenAddress = _tokenAddress;                      // VTB token Address
        VTB          = VTBToken(tokenAddress);
    }

    // -------------------------------------------------
    // Changes main contribution wallet
    // -------------------------------------------------
    function changeWalletAddress(address _wallet) external onlyOwner {
        wallet = _wallet;
        WalletAddressChanged(_wallet);
    }

    // -------------------------------------------------
    // Opens the crowdfunding
    // -------------------------------------------------
    function openCrowdfund() external onlyOwner returns (bool success) {
        VTB.startCrowdfund();
        return true;
    }

    // -------------------------------------------------
    // Function to buy VTB. One can also buy VTB by calling this function directly and send
    // it to another destination.
    // -------------------------------------------------
    function buyTokens(address _to) public crowdfundIsActive nonZeroAddress(_to) nonZeroValue payable {
        uint256 weiAmount = msg.value;
        uint256 tokens;
        uint price = 2100;

        tokens = weiAmount * price;
        if (!VTB.transferFromCrowdfund(_to, tokens)) {revert();}
        TokenPurchase(_to, weiAmount, tokens);

        weiRaised = weiRaised.add(weiAmount);
        wallet.transfer(weiAmount);
    }

    // -------------------------------------------------
    // Closes the crowdfunding. Any unsold VTB will go back to the foundation.
    // -------------------------------------------------
    function closeCrowdfund() external notBeforeCrowdfundEnds onlyOwner returns (bool success) {
        AmountRaised(wallet, weiRaised);
        VTB.finalizeCrowdfund();
        return true;
    }

/*----------------- Entry point -----------------*/

    // -------------------------------------------------
    // To contribute, send a value transaction to the crowdfund address.
    // Please include at least 100000 gas.
    // -------------------------------------------------
    function () public payable {
        buyTokens(msg.sender);
    }
}
