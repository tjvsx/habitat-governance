const { expect } = require('chai');

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { ethers } = require('hardhat');
const { deployDiamond } = require('../scripts/deploy.js');


describe('Diamond', function () {
  let dao;
  let user1
  let user2;
  let user3;
  let diamond;
  let tokenfacet;
  let governancefacet;

  describe('Facets', function () {

    before(async function () {
      [dao, user1, user2, user3] = await ethers.getSigners();
    });
  
    beforeEach(async function () {
      //deploy diamond contract
      const DiamondFactory = await ethers.getContractFactory('Gem');
      diamond = await DiamondFactory.deploy();
      await diamond.deployed();

      //deploy offchain cut initializer contract
      const InitVoting = await ethers.getContractFactory('InitVoting');
      const initvoting = await InitVoting.deploy();
      await initvoting.deployed();

      //deploy uninitialized token contract
      const TokenFactory = await ethers.getContractFactory('Token');
      const token = await TokenFactory.deploy();
      await token.deployed();

      //deploy uninitialized governance contract
      const GovernanceFactory = await ethers.getContractFactory('Governance');
      const governance = await GovernanceFactory.deploy();
      await governance.deployed();

      //declare facets to be cut
      const facetCuts = [
        {
          target: token.address,
          action: 0,
          selectors: Object.keys(token.interface.functions)
          // .filter((fn) => fn != 'init()')
          .map((fn) => token.interface.getSighash(fn),
          ),
        },
        {
          target: governance.address,
          action: 0,
          selectors: Object.keys(governance.interface.functions)
          .map((fn) => governance.interface.getSighash(fn),
          ),
        },
      ];
  
      //do the cut
      await diamond
        .connect(dao)
        .diamondCut(facetCuts, initvoting.address, '0xe1c7392a'); // initialize data ->
        // -> call init() via initvoting address and sighash. /// 0xe1c7392a = init()

      tokenfacet = await ethers.getContractAt('Token', diamond.address)
      governancefacet = await ethers.getContractAt('Governance', diamond.address)
    });

    describe('Token', function() {

      it('function calls should return the value', async function() {

        expect(await tokenfacet.decimals()).to.equal(8);

      });
    });

    describe('Governance', function() {

      it('proposals should pass and execute', async function() {

        await tokenfacet.transfer(user1.address, 300)

        expect(await tokenfacet.totalSupply()).to.equal(1000)

        // predeploy proposalcontract
        const TokenMinterFactory = await ethers.getContractFactory('TokenMinter');
        const tokenminter = await TokenMinterFactory.deploy();
        await tokenminter.deployed();
        const proposalContract = tokenminter.address;

        const currentBlock = await ethers.provider.getBlockNumber();
        const timestamp = (await ethers.provider.getBlock(currentBlock)).timestamp;
        const deadline = timestamp + 10;

        await governancefacet.propose(proposalContract, ethers.constants.AddressZero, deadline);

        await governancefacet.connect(user1).vote(0, true)

        await network.provider.send("evm_setNextBlockTimestamp", [deadline + 1])
        await network.provider.send("evm_mine");

        await governancefacet.executeProposal(0);

        // governance proposal passed
        expect(await governancefacet.proposalStatus(0)).to.equal(5);

        // check that new tokens were minted
        expect(await tokenfacet.totalSupply()).to.be.above(1500)
      });

      it('execute function can cut in new facets', async function() {

        // some dao's predeployed facet contract
        const TestFacetFactory = await ethers.getContractFactory('TestFacet')
        const testcontract = await TestFacetFactory.deploy()
        await testcontract.deployed()

        const facetCuts = [
          {
            target: testcontract.address,
            action: 0,
            selectors: Object.keys(testcontract.interface.functions)
            .map((fn) => testcontract.interface.getSighash(fn),
            ),
          },
        ];

        //determine the diamantaire selectors.length to use
        const diamantaireType = ('Diamantaire').concat(facetCuts[0].selectors.length)
        console.log('using diamantaire contract:', diamantaireType)

        // some dao's predeployed diamantaire (proposalcontract)
        const DiamantaireFactory = await ethers.getContractFactory(diamantaireType);
        const diamantaire = await DiamantaireFactory.deploy(facetCuts)
        await diamantaire.deployed();
        const proposalContract = diamantaire.address;

        //proposer deploys diamoncut initializer - inits state vars of facet
        const InitTest = await ethers.getContractFactory('InitTest')
        const inittest = await InitTest.deploy()
        await inittest.deployed()

        const currentBlock = await ethers.provider.getBlockNumber();
        const timestamp = (await ethers.provider.getBlock(currentBlock)).timestamp;

        const deadline = timestamp + 10;
        const initializer = inittest.address;

        await governancefacet.propose(proposalContract, initializer, deadline);

        await governancefacet.connect(user1).vote(0, true)

        await network.provider.send("evm_setNextBlockTimestamp", [deadline + 1])
        await network.provider.send("evm_mine");

        await governancefacet.executeProposal(0/* , {gasLimit: 300000} */);

        // governance proposal passed
        expect(await governancefacet.proposalStatus(0)).to.equal(5);

        // // check if testfacet is callable via diamond and has initialized state
        // const testfacet = await ethers.getContractAt('TestFacet', diamond.address)
        // expect(await testfacet.getInitializedValue()).to.equal(true);
        
      });
    });
  });
});