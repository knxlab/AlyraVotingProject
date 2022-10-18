// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

abstract contract DonateToChildrenCancerAssoc {

    address childrenCancerAssociationAddress = 0x8ee9700900aF3a91119D3Ff65935782575e5347f;
    uint public totalDonation;
    event ValueReceived(address user, uint amount);

    function getAssociationUrl() external pure returns(string memory) {
        return "https://thegivingblock.com/donate/childrens-cancer-association/";
    }
    
    receive() external payable {
        totalDonation += msg.value;
        payable(childrenCancerAssociationAddress).transfer(msg.value);
        emit ValueReceived(msg.sender, msg.value);
    }
}