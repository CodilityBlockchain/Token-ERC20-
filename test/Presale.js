// Import necessary modules from Hardhat
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Presale Contract", function () {
    let presaleContract;
    let owner;
    let user1;
    let user2;
    let token;

    beforeEach(async function () {
        // Deploy the Presale contract
        [owner, user1, user2] = await ethers.getSigners();
        const Presale = await ethers.getContractFactory("Presale");
        presaleContract = await Presale.deploy();
        await presaleContract.deployed();

        // Deploy a mock ERC20 token for testing
        const Token = await ethers.getContractFactory("MockERC20");
        token = await Token.deploy("MockToken", "MT", 18);
        await token.deployed();
    });

    it("should initialize a presale", async function () {
        const price = ethers.utils.parseEther("0.01");
        await token.approve(presaleContract.address, ethers.utils.parseEther("1"));

        await presaleContract.inititalize(
            token.address,
            ethers.utils.parseEther("1000"),
            price,
            { value: ethers.utils.parseEther("0.0001") }
        );

        const presaleDetails = await presaleContract.getPresaleDetails(1);

        expect(presaleDetails[0]).to.equal(token.address);
        expect(presaleDetails[1]).to.equal(owner.address);
        expect(presaleDetails[5]).to.equal(true);
    });

    it("should allow users to buy tokens from a presale", async function () {
        const price = ethers.utils.parseEther("0.01");
        await token.approve(presaleContract.address, ethers.utils.parseEther("1"));

        await presaleContract.inititalize(
            token.address,
            ethers.utils.parseEther("1000"),
            price,
            { value: ethers.utils.parseEther("0.0001") }
        );

        const user1BalanceBefore = await token.balanceOf(user1.address);

        await presaleContract.connect(user1).buy(1, { value: ethers.utils.parseEther("0.01") });

        const user1BalanceAfter = await token.balanceOf(user1.address);

        expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(ethers.utils.parseEther("1"));
    });

    it("should allow users to close a presale and refund remaining tokens", async function () {
        const price = ethers.utils.parseEther("0.01");
        await token.approve(presaleContract.address, ethers.utils.parseEther("1"));

        await presaleContract.inititalize(
            token.address,
            ethers.utils.parseEther("1000"),
            price,
            { value: ethers.utils.parseEther("0.0001") }
        );

        await presaleContract.connect(user1).buy(1, { value: ethers.utils.parseEther("0.01") });

        const user1BalanceBefore = await token.balanceOf(user1.address);

        await presaleContract.connect(user1).closePresale(1);

        const user1BalanceAfter = await token.balanceOf(user1.address);

        expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(ethers.utils.parseEther("1000"));
    });
});
