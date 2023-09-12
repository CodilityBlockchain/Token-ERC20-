const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Presale1", function () {
    let Presale1;
    let presale1;
    let owner;
    let user1;
    let user2;
    let token;

    beforeEach(async function () {
        [owner, user1, user2] = await ethers.getSigners();

        // Deploy the Presale1 contract
        const Presale1Factory = await ethers.getContractFactory("Presale1");
        presale1 = await Presale1Factory.deploy();

        // Deploy a sample ERC20 token for testing
        const ERC20Factory = await ethers.getContractFactory("YourERC20Token"); // Replace with your ERC20 token contract
        token = await ERC20Factory.deploy();

        // Initialize the Presale1 contract with the ERC20 token
        await presale1.inititalize(token.address, ethers.utils.parseEther("100"), ethers.utils.parseEther("0.1"));
    });

    it("should initialize correctly", async function () {
        const presaleInfo = await presale1.getPresaleDetails(1);

        expect(presaleInfo[0]).to.equal(token.address); // Check if the correct token is set
        expect(presaleInfo[1]).to.equal(owner.address); // Check if the correct owner is set
        expect(presaleInfo[3]).to.equal(ethers.utils.parseEther("100")); // Check if the correct amount is set
        expect(presaleInfo[4]).to.equal(ethers.utils.parseEther("100")); // Check if the remaining amount is correct
        expect(presaleInfo[5]).to.equal(ethers.utils.parseEther("0.1")); // Check if the correct price is set
        expect(presaleInfo[6]).to.equal(true); // Check if the presale is active
    });

    it("should allow users to buy tokens", async function () {
        // User1 buys tokens
        await expect(() => presale1.connect(user1).buy(1, { value: ethers.utils.parseEther("10") }))
            .to.changeTokenBalance(token, user1, ethers.utils.parseEther("100"));

        // Check if the remaining amount is updated
        const presaleInfo = await presale1.getPresaleDetails(1);
        expect(presaleInfo[4]).to.equal(ethers.utils.parseEther("90"));

        // User2 tries to buy tokens with insufficient funds
        await expect(presale1.connect(user2).buy(1, { value: ethers.utils.parseEther("5") })).to.be.revertedWith(
            "value less than price"
        );

        // User1 tries to buy more tokens than available
        await expect(presale1.connect(user1).buy(1, { value: ethers.utils.parseEther("1000") })).to.be.revertedWith(
            "insufficient remaining amount"
        );
    });

    it("should allow the owner to close the presale", async function () {
        await presale1.connect(owner).closePresale(1);

        const presaleInfo = await presale1.getPresaleDetails(1);
        expect(presaleInfo[6]).to.equal(false); // Check if the presale is no longer active
        expect(presaleInfo[4]).to.equal(0); // Check if the remaining amount is zero
    });

    it("should allow the owner to add more tokens", async function () {
        // Add more tokens to the presale
        await token.connect(owner).approve(presale1.address, ethers.utils.parseEther("100"));
        await presale1.connect(owner).addMoreTokens(1, ethers.utils.parseEther("50"));

        const presaleInfo = await presale1.getPresaleDetails(1);
        expect(presaleInfo[3]).to.equal(ethers.utils.parseEther("150")); // Check if the amount is updated
        expect(presaleInfo[4]).to.equal(ethers.utils.parseEther("150")); // Check if the remaining amount is updated
    });
});
