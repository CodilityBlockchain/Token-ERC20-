// Import necessary modules and artifacts
const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('TokenFactory', function () {
    let owner;
    let tokenFactory;

    beforeEach(async function () {
        // Deploy the TokenFactory contract
        [owner] = await ethers.getSigners();
        const TokenFactory = await ethers.getContractFactory('TokenFactory');
        tokenFactory = await TokenFactory.deploy();

        // Wait for the contract to be mined
        await tokenFactory.deployed();
    });

    it('should deploy the TokenFactory contract', async function () {
        expect(tokenFactory.address).to.not.equal(0);
    });

    it('should create a new ERC-20 token', async function () {
        const name = 'TestToken';
        const symbol = 'TTT';
        const decimals = 18;

        // Create a new token using the TokenFactory contract
        await tokenFactory.createToken(name, symbol, decimals);

        // Get the list of deployed tokens
        const deployedTokens = await tokenFactory.getDeployedTokens();

        // Expect the deployedTokens array to contain the new token's address
        expect(deployedTokens.length).to.equal(1);
        expect(deployedTokens[0]).to.not.equal(0);

        // Get the instance of the newly created token
        const Token = await ethers.getContractFactory('Token');
        const token = Token.attach(deployedTokens[0]);

        // Verify the token's properties
        expect(await token.name()).to.equal(name);
        expect(await token.symbol()).to.equal(symbol);
        expect(await token.decimals()).to.equal(decimals);
        expect(await token.Owner()).to.equal(owner.address);
    });
});
