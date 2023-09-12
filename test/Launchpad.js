const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Launchpad Contract", function () {
    let launchpad;
    let owner;
    let user1;
    let user2;
    let token;

    before(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        // Deploy the Launchpad contract
        const Launchpad = await ethers.getContractFactory("Launchpad");
        launchpad = await Launchpad.deploy();
        await launchpad.deployed();

        // Deploy a sample ERC20 token for testing
        const SampleToken = await ethers.getContractFactory("SampleToken");
        token = await SampleToken.deploy();
        await token.deployed();
    });

    it("Should create a presale with BNB", async function () {
        const amount = ethers.utils.parseEther("10"); // 10 BNB
        const startTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
        const endTime = startTime + 3600; // 1 hour after start
        const softCap = ethers.utils.parseEther("5"); // 5 BNB
        const hardCap = ethers.utils.parseEther("20"); // 20 BNB
        const minimumInvestment = ethers.utils.parseEther("1"); // 1 BNB
        const maximumInvestment = ethers.utils.parseEther("10"); // 10 BNB

        await launchpad.connect(owner).createPresaleBNB(
            token.address,
            "Metadata",
            amount,
            1000, // Price
            startTime,
            endTime,
            softCap,
            hardCap,
            minimumInvestment,
            maximumInvestment
        );

        const presaleDetail = await launchpad.getPresaleDetail(1);
        expect(presaleDetail.tokenAddress).to.equal(token.address);
        expect(presaleDetail.seller).to.equal(owner.address);
        // Add more assertions as needed
    });

    it("Should invest in a presale with BNB", async function () {
        // Assuming a presale has already been created

        const user1Investment = ethers.utils.parseEther("2"); // 2 BNB
        await expect(
            launchpad.connect(user1).investWithBNB(1, user1Investment, { value: user1Investment })
        ).to.emit(launchpad, "InvesWithBNB");

        // Add assertions for successful investment
    });

    it("Should create a presale with a token payment", async function () {
        const amount = ethers.utils.parseEther("1000"); // Number of tokens
        const startTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
        const endTime = startTime + 3600; // 1 hour after start
        const softCap = ethers.utils.parseEther("500"); // Number of tokens
        const hardCap = ethers.utils.parseEther("2000"); // Number of tokens
        const minimumInvestment = ethers.utils.parseEther("100"); // Number of tokens
        const maximumInvestment = ethers.utils.parseEther("1000"); // Number of tokens

        await launchpad.connect(owner).createPresaleToken(
            token.address,
            "Metadata",
            token,
            amount,
            1000, // Price
            startTime,
            endTime,
            softCap,
            hardCap,
            minimumInvestment,
            maximumInvestment
        );

        const presaleDetail = await launchpad.getPresaleDetail(2);
        expect(presaleDetail.tokenAddress).to.equal(token.address);
        expect(presaleDetail.seller).to.equal(owner.address);
        // Add more assertions as needed
    });

});
