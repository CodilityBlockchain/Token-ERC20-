const { expect } = require("chai");

describe("Airdrop1 Contract", function () {
  let Airdrop1;
  let airdrop1;
  let owner;
  let user1;
  let user2;
  let token;

  const INITIAL_SUPPLY = ethers.utils.parseEther("1000000");

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    // Deploy a mock ERC20 token contract
    const ERC20Mock = await ethers.getContractFactory("ERC20Mock");
    token = await ERC20Mock.deploy(owner.address, INITIAL_SUPPLY);
    await token.deployed();

    // Deploy Airdrop1 contract
    Airdrop1 = await ethers.getContractFactory("Airdrop1");
    airdrop1 = await Airdrop1.deploy();
    await airdrop1.deployed();

    // Initialize the Airdrop with the token
    await token.approve(airdrop1.address, INITIAL_SUPPLY);
    await airdrop1.inititalize(token.address, INITIAL_SUPPLY, ethers.utils.parseEther("100"));
  });

  it("should initialize the contract correctly", async function () {
    // Check if the platform owner is correctly set
    expect(await airdrop1.platformOwner()).to.equal(owner.address);

    // Check if the airdropInfo mapping is correctly initialized
    const airdropInfo = await airdrop1.getAirdropDetails(1);
    expect(airdropInfo[0]).to.equal(token.address); // Token address
    expect(airdropInfo[1]).to.equal(owner.address); // User address
    expect(airdropInfo[2]).to.equal(INITIAL_SUPPLY); // Total amount
    expect(airdropInfo[3]).to.equal(INITIAL_SUPPLY); // Remaining amount
    expect(airdropInfo[6]).to.equal(true); // IsActive should be true
  });

  it("should allow users to claim airdrops", async function () {
    // User 1 claims the airdrop
    await airdrop1.connect(user1).claim(1);

    // Check if the user has successfully claimed the airdrop
    const claimedByUser1 = await airdrop1.claimed(1);
    expect(claimedByUser1).to.equal(user1.address);

    // Check if the remaining amount has been reduced
    const airdropInfo = await airdrop1.getAirdropDetails(1);
    expect(airdropInfo[3]).to.equal(INITIAL_SUPPLY.sub(ethers.utils.parseEther("100")));
  });

  it("should not allow users to claim the same airdrop twice", async function () {
    // User 1 claims the airdrop
    await airdrop1.connect(user1).claim(1);

    // Try to claim again, it should fail
    await expect(airdrop1.connect(user1).claim(1)).to.be.revertedWith("already claimed");
  });

  it("should allow the platform owner to add more tokens to the airdrop", async function () {
    const additionalTokens = ethers.utils.parseEther("500");

    // Add more tokens to the airdrop by the platform owner
    await airdrop1.addMoreTokens(1, additionalTokens);

    // Check if the total amount and remaining amount have increased
    const airdropInfo = await airdrop1.getAirdropDetails(1);
    expect(airdropInfo[2]).to.equal(INITIAL_SUPPLY.add(additionalTokens));
    expect(airdropInfo[3]).to.equal(INITIAL_SUPPLY.add(additionalTokens));
  });
});
