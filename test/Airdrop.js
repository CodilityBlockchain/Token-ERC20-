const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Airdrop Contract", function () {
    let airdropContract;
    let token;
    let owner;
    let user1;
    let user2;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        const Token = await ethers.getContractFactory("IERC20");
        token = await Token.deploy();

        const Airdrop = await ethers.getContractFactory("Airdrop");
        airdropContract = await Airdrop.deploy();
    });

    it("Should initialize the contract with the correct platform owner", async function () {
        expect(await airdropContract.platformOwner()).to.equal(owner.address);
    });

    it("Should create a new airdrop", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        const airdropDetails = await airdropContract.getAirdropDetails(1);
        expect(airdropDetails[0]).to.equal(token.address);
        expect(airdropDetails[1]).to.equal(owner.address);
        expect(airdropDetails[2]).to.equal(amount);
        expect(airdropDetails[3]).to.equal(amount);
        expect(airdropDetails[4]).to.deep.equal([]);
        expect(airdropDetails[5]).to.equal(amountPeruser);
        expect(airdropDetails[6]).to.equal(true);
    });

    it("Should not create a duplicate airdrop for the same token", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        // Attempt to create a duplicate airdrop
        await expect(
            airdropContract.inititalize(token.address, amount, amountPeruser)
        ).to.be.revertedWith("already airdropped");
    });

    it("Should allow a user to claim tokens from an active airdrop", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        const user1BalanceBefore = await token.balanceOf(user1.address);

        await airdropContract.connect(user1).claim(1);

        const user1BalanceAfter = await token.balanceOf(user1.address);

        expect(user1BalanceAfter.sub(user1BalanceBefore)).to.equal(amountPeruser);
    });

    it("Should not allow a user to claim from an inactive airdrop", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);
        await airdropContract.connect(owner).closeAirdrop(1);

        await expect(airdropContract.connect(user1).claim(1)).to.be.revertedWith(
            "not active"
        );
    });

    it("Should not allow a user to claim tokens more than the remaining amount", async function () {
        const amount = ethers.utils.parseEther("20");
        const amountPeruser = ethers.utils.parseEther("10");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        await airdropContract.connect(user1).claim(1);

        // Attempt to claim more tokens than remaining
        await expect(airdropContract.connect(user2).claim(1)).to.be.revertedWith(
            "insufficient remaining amount"
        );
    });

    it("Should allow the owner to close an active airdrop and refund remaining tokens", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        const ownerBalanceBefore = await token.balanceOf(owner.address);

        await airdropContract.connect(owner).closeAirdrop(1);

        const ownerBalanceAfter = await token.balanceOf(owner.address);
        const airdropDetails = await airdropContract.getAirdropDetails(1);

        expect(ownerBalanceAfter.sub(ownerBalanceBefore)).to.equal(amount);
        expect(airdropDetails[3]).to.equal(0);
        expect(airdropDetails[6]).to.equal(false);
    });

    it("Should allow the owner to add more tokens to an airdrop", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");
        const additionalAmount = ethers.utils.parseEther("50");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        await airdropContract.connect(owner).addMoreTokens(1, additionalAmount);

        const airdropDetails = await airdropContract.getAirdropDetails(1);

        expect(airdropDetails[2]).to.equal(amount.add(additionalAmount));
        expect(airdropDetails[3]).to.equal(amount.add(additionalAmount));
    });

    it("Should not allow a user to add more tokens to an airdrop", async function () {
        const amount = ethers.utils.parseEther("100");
        const amountPeruser = ethers.utils.parseEther("10");
        const additionalAmount = ethers.utils.parseEther("50");

        await token.transfer(airdropContract.address, amount);
        await airdropContract.inititalize(token.address, amount, amountPeruser);

        // Attempt to add more tokens as a user
        await expect(
            airdropContract.connect(user1).addMoreTokens(1, additionalAmount)
        ).to.be.revertedWith("invalid user");
    });
});
