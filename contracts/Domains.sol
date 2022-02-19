// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// We first import some OpenZeppelin Contracts.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {StringUtils} from "./libraries/StringUtils.sol";
// We import another help function
import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

// We inherit the contract we imported. This means we'll have access
// to the inherited contract's methods.
contract Domains is ERC721URIStorage {
    // Magic given to us by OpenZeppelin to help us keep track of tokenIds.
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    string public tld;

    // We'll be storing our NFT images on chain as SVGs
    string svgPartOne =
        '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#a)" d="M0 0h270v270H0z"/><defs><filter id="b" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M64.72 56.787a12 12 0 0 0-9.734 13.902l2.778 15.757A12 12 0 0 0 81.4 82.278l-2.78-15.757a12 12 0 0 0-13.901-9.734Zm-5.638 16.977 16.742-2.952 1.476 8.371-16.742 2.952Zm11.976 18.969a8.54 8.54 0 0 1-9.847-6.895l-.045-.256 16.742-2.952.045.256a8.54 8.54 0 0 1-6.895 9.847Zm4.158-25.368-16.742 2.952-.041-.236a8.5 8.5 0 0 1 16.741-2.952Zm21.577 2.471-15.274-9.918 3.16 17.923a8 8 0 0 0 15.757-2.778 7.66 7.66 0 0 0-3.643-5.227Zm-3.454 11.048a4.5 4.5 0 0 1-5.213-3.65l-1.771-10.045 8.532 5.542a4.1 4.1 0 0 1 1.969 2.76 4.5 4.5 0 0 1-3.517 5.393Zm-55.93 5.293a8 8 0 0 0 15.756-2.779l-3.16-17.923-10.961 14.544a7.76 7.76 0 0 0-1.636 6.158Zm4.342-3.934 6.196-8.282 1.771 10.045a4.5 4.5 0 0 1-8.863 1.563 4.1 4.1 0 0 1 .896-3.326ZM61.187 48.27a7 7 0 1 0-5.678 8.11 7 7 0 0 0 5.678-8.11Zm-10.34 1.824a3.5 3.5 0 1 1 4.055 2.839 3.54 3.54 0 0 1-4.055-2.84Zm19.958-10.627a7 7 0 1 0 8.109 5.678 7 7 0 0 0-8.11-5.678Zm1.823 10.34a3.5 3.5 0 1 1 2.84-4.054 3.54 3.54 0 0 1-2.84 4.054Z" fill="#fff"/><defs><linearGradient id="a" x1="0" y1="0" x2="250" y2="250" gradientUnits="userSpaceOnUse"><stop stop-color="#ffaa17"/><stop offset="1" stop-color="#ffff17" stop-opacity=".99"/></linearGradient></defs><path d="M16 10a6 6 0 0 0-6 6v8a6 6 0 0 0 12 0v-8a6 6 0 0 0-6-6Zm-4.25 7.87h8.5v4.25h-8.5ZM16 28.25A4.27 4.27 0 0 1 11.75 24v-.13h8.5V24A4.27 4.27 0 0 1 16 28.25Zm4.25-12.13h-8.5V16a4.25 4.25 0 0 1 8.5 0Zm10.41 3.09L24 13v9.1a4 4 0 0 0 8 0 3.83 3.83 0 0 0-1.34-2.89ZM28 24.35a2.25 2.25 0 0 1-2.25-2.25V17l3.72 3.47A2.05 2.05 0 0 1 30.2 22a2.25 2.25 0 0 1-2.2 2.35ZM0 22.1a4 4 0 0 0 8 0V13l-6.66 6.21A3.88 3.88 0 0 0 0 22.1Zm2.48-1.56L6.25 17v5.1a2.25 2.25 0 0 1-4.5 0 2.05 2.05 0 0 1 .73-1.56ZM15 5.5A3.5 3.5 0 1 0 11.5 9 3.5 3.5 0 0 0 15 5.5Zm-5.25 0a1.75 1.75 0 1 1 1.75 1.75A1.77 1.77 0 0 1 9.75 5.5ZM20.5 2A3.5 3.5 0 1 0 24 5.5 3.5 3.5 0 0 0 20.5 2Zm0 5.25a1.75 1.75 0 1 1 1.75-1.75 1.77 1.77 0 0 1-1.75 1.75Z"/><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#b)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string svgPartTwo = "</text></svg>";

    mapping(string => address) public domains;
    mapping(string => string) public records;

    constructor(string memory _tld)
        payable
        ERC721("Hive Name Service", "HNS")
    {
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    function register(string calldata name) public payable {
        require(domains[name] == address(0));

        uint256 _price = this.price(name);
        require(msg.value >= _price, "Not enough Matic paid");

        // Combine the name passed into the function  with the TLD
        string memory _name = string(abi.encodePacked(name, ".", tld));
        // Create the SVG (image) for the NFT with the name
        string memory finalSvg = string(
            abi.encodePacked(svgPartOne, _name, svgPartTwo)
        );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            "Registering %s.%s on the contract with tokenID %d",
            name,
            tld,
            newRecordId
        );

        // Create the JSON metadata of our NFT. We do this by combining strings and encoding as base64
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        _name,
                        '", "description": "A domain on the Hive name service", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '","length":"',
                        strLen,
                        '"}'
                    )
                )
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log(
            "\n--------------------------------------------------------"
        );
        console.log("Final tokenURI", finalTokenUri);
        console.log(
            "--------------------------------------------------------\n"
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        _tokenIds.increment();
    }

    // This function will give us the price of a domain based on length
    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**17; // 5 MATIC = 5 000 000 000 000 000 000 (18 decimals). We're going with 0.5 Matic cause the faucets don't give a lot
        } else if (len == 4) {
            return 3 * 10**17; // To charge smaller amounts, reduce the decimals. This is 0.3
        } else {
            return 1 * 10**17;
        }
    }

    function getAddress(string calldata name) public view returns (address) {
        // Check that the owner is the transaction sender
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        // Check that the owner is the transaction sender
        require(domains[name] == msg.sender);
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }
}
