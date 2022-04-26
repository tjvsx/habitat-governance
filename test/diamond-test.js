const { expect } = require('chai');
const { deployMockContract } = require('ethereum-waffle');
const { ethers } = require('hardhat');

//governance upgrade global vars
async function governanceFacetCut() {
  //deploy offchain cut initializer contract
  const InitGovernance = await ethers.getContractFactory('GovernanceTokenInit');
  const initgovernance = await InitGovernance.deploy();
  await initgovernance.deployed();

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

  return {
    facetCuts,
    initgovernance
  }
  
}

// multisig global vars
let multisig;
let signers;
let nonce;
let address;
async function multisigTX(target, data, value, delegate) {
  nonce = nextNonce();
  address = multisig.address;

  let signatures = [];
  for (let signer of signers) {
    let sig = await signer.signMessage(hashData({
      values: [target, data, value, delegate],
      types: ['address', 'bytes', 'uint256', 'bool'],
      nonce,
      address,
    }));
    signatures.push({ data: sig, nonce });
  }

  await multisig.verifyAndExecute(
    { target, data, value, delegate },
    signatures,
    { value },
  );

  return true;
}
let currentNonce = ethers.constants.Zero;
const nextNonce = function () {
  currentNonce = currentNonce.add(ethers.constants.One);
  return currentNonce;
};
function hashData({ types, values, nonce, address }) {
  const hash = ethers.utils.solidityKeccak256(
    [...types, 'uint256', 'address'],
    [...values, nonce, address],
  );
  return ethers.utils.arrayify(hash);
}

describe('Diamond', function () {
  let dao;
  let user1
  let user2;
  let user3;
  let diamond;
  let proxy;
  let cutterfacet;
  let louperfacet;
  let ownerfacet;
  let tokenfacet;
  let governancefacet;
  let habitatrepo;

  describe('Scenarios', function () {

    before(async function () {
      [dao, user1, user2, user3] = await ethers.getSigners();

      //predeploy loupe facet contract
      const LouperFactory = await ethers.getContractFactory('DiamondLoupeFacet');
      const louper = await LouperFactory.deploy();
      await louper.deployed();

      //predeploy ownership facet contract
      const OwnerFactory = await ethers.getContractFactory('OwnershipFacet');
      const owner = await OwnerFactory.deploy();
      await owner.deployed();

      //predeploy repo contract
      const HabitatRepository = await ethers.getContractFactory('HabitatRepository');
      habitatrepo = await HabitatRepository.deploy(dao.address, [owner.address, louper.address]);
      await habitatrepo.deployed();

      //predeploy diamondCut facet contract
      const CutterFactory = await ethers.getContractFactory('DiamondCutFacet');
      const cutter = await CutterFactory.deploy();
      await cutter.deployed();

      const facetCuts = [
        {
          target: cutter.address,
          action: 0,
          selectors: Object.keys(cutter.interface.functions)
          // .filter((fn) => fn != 'init()')
          .map((fn) => cutter.interface.getSighash(fn),
          ),
        },
        {
          target: louper.address,
          action: 0,
          selectors: Object.keys(louper.interface.functions)
          .map((fn) => louper.interface.getSighash(fn),
          ),
        },
        {
          target: owner.address,
          action: 0,
          selectors: Object.keys(owner.interface.functions)
          .map((fn) => owner.interface.getSighash(fn),
          ),
        },
      ];

      //deploy diamond contract
      const DiamondFactory = await ethers.getContractFactory('Diamond');
      diamond = await DiamondFactory.connect(dao).deploy(facetCuts, habitatrepo.address);
      await diamond.connect(dao).deployed()

      cutterfacet = await ethers.getContractAt('DiamondCutFacet', diamond.address)
      louperfacet = await ethers.getContractAt('DiamondLoupeFacet', diamond.address)
      ownerfacet = await ethers.getContractAt('OwnershipFacet', diamond.address)
    });

    describe('Single User', function() {

      it('user clones with new diamond', async function () {
        // get facets
        const facets = await louperfacet.facets();

        // convert to facetCuts[] objects
        let facetCuts = [];
        let target;
        let selectors;
        let action = 0;
        for (let i = 0; i < facets.length; i++) {
          target = facets[i].target;
          selectors = facets[i].selectors;
          facetCuts.push({
            target,
            action,
            selectors
          })
        }

        //deploy new diamond contract with cuts in constructor
        const NewDiamondFactory = await ethers.getContractFactory('Diamond');
        const newDiamond = await NewDiamondFactory.connect(user1).deploy(facetCuts, habitatrepo.address);
        await newDiamond.deployed();

        // functions of diamond are accessible via newdiamond, but newdiamond holds its own state
        const newDiamond_Owner = await ethers.getContractAt('OwnershipFacet', newDiamond.address)
        expect(await newDiamond_Owner.owner()).to.equal(user1.address)
      });

      it('user clones with proxy', async function() {
        //deploy normal proxy that mirrors diamond
        const ProxyFactory = await ethers.getContractFactory('DiamondProxy')
        proxy = await ProxyFactory.connect(user1).deploy(diamond.address);
        await proxy.deployed()

        // functions of diamond are accessible via proxy, but proxy holds its own state
        const proxy_ownerfacet = await ethers.getContractAt('OwnershipFacet', proxy.address)
        expect(await proxy_ownerfacet.owner()).to.equal(user1.address)
      });

      // it('upgrades to governance ownership', async function() { /// for visual aid, diamond ownership state changes affect other tests

      //   const { facetCuts, initgovernance } = await governanceFacetCut();
      //   //do the cut
      //   await cutterfacet
      //     .connect(dao)
      //     .diamondCut(facetCuts, initgovernance.address, '0xe1c7392a'); //0xe1c7392a = 'init()'
  
      //   tokenfacet = await ethers.getContractAt('Token', diamond.address)
      //   governancefacet = await ethers.getContractAt('Governance', diamond.address)

      //   expect(await tokenfacet.decimals()).to.equal(8)
      // });
    });

    describe('Multisig', function() {

      before(async function () {
        // multisig vars
        signers = [user1, user2, user3];
        let target;
        let data;
        let value;
        let delegate;

        //deploy multisig
        const MultisigFactory = await ethers.getContractFactory('Multisig');
        const signerAddresses = [user1.address, user2.address, user3.address]
        const quorum = 2;
        multisig = await MultisigFactory.deploy(signerAddresses, quorum);
        await multisig.deployed();

        //transfer ownership of diamond to multisig
        await ownerfacet.connect(dao).transferOwnership(multisig.address);

        // fill transaction data
        target = diamond.address;
        ({ data } = 
          await ownerfacet.populateTransaction.acceptOwnership() 
        );
        value = ethers.constants.Zero;
        delegate = false;
        await multisigTX(target, data, value, delegate);

        // check if diamond owner is multisig
        expect(await ownerfacet.owner()).to.equal(multisig.address)
      });


      it('can upgrade to governance', async function() {

        //declare cuts
        const { facetCuts, initgovernance } = await governanceFacetCut();

        // fill transaction data
        target = diamond.address;
        ({ data } = 
          await cutterfacet.populateTransaction.diamondCut(facetCuts, initgovernance.address, '0xe1c7392a')
        );
        value = ethers.constants.Zero;
        delegate = false;
        await multisigTX(target, data, value, delegate);

        tokenfacet = await ethers.getContractAt('Token', diamond.address)
        governancefacet = await ethers.getContractAt('Governance', diamond.address)

        // diamond owns itself - no going back
        expect(await ownerfacet.owner()).to.equal(diamond.address);

        // token functions pass
        expect(await tokenfacet.decimals()).to.equal(8);

        // proxy can call token functions too
        const proxy_tokenfacet = await ethers.getContractAt('Token', proxy.address)
        expect(await proxy_tokenfacet.decimals()).to.equal(0)

      });

      it('can distribute tokens from multisig', async function() {
          // send multiple - look up multisend via multisig?
          target = diamond.address;
          ({ data } = 
            await tokenfacet.populateTransaction.transfer(user1.address, 300)
          );
          value = ethers.constants.Zero;
          delegate = false;
          await multisigTX(target, data, value, delegate);
          ({ data } = 
            await tokenfacet.populateTransaction.transfer(user2.address, 300)
          );
          await multisigTX(target, data, value, delegate);
      });
    });


    describe('Governance', function() {
      
      let upgradeRegistry;

      before(async function(){
        //predeploy UpgradeRegistry
        const UpgradeRegistryFactory = await ethers.getContractFactory('UpgradeRegistry')
        upgradeRegistry = await UpgradeRegistryFactory.deploy();
        await upgradeRegistry.deployed()

        // set dummy greeter upgrade in parent contract - for security
        const GreeterFactory = await ethers.getContractFactory('Greeter')
        greeter = await GreeterFactory.deploy();
        await greeter.deployed()
        const facetCuts = [
          {
            target: greeter.address,
            action: 0,
            selectors: Object.keys(greeter.interface.functions)
            .map((fn) => greeter.interface.getSighash(fn),
            ),
          },
        ];
        await upgradeRegistry.set(diamond.address, facetCuts, ethers.constants.AddressZero, '0x');
      });

      describe('DiamondCuts', function() {
        let testfacet1;
        let testfacet2;
        let testinit;
        let proposalContract;

        before(async function() {

          // some dao's predeployed facet contract
          const TestFacet1Factory = await ethers.getContractFactory('TestFacet1')
          testfacet1 = await TestFacet1Factory.deploy()
          await testfacet1.deployed()

          // some dao's predeployed facet contract
          const TestFacet2Factory = await ethers.getContractFactory('TestFacet2')
          testfacet2 = await TestFacet2Factory.deploy()
          await testfacet2.deployed()

          //proposer deploys diamondcut initializer - inits state vars of facet
          const TestInit = await ethers.getContractFactory('TestInit')
          testinit = await TestInit.deploy()
          await testinit.deployed()
        })

        it('registers facets for governance-use', async function() {
          const facetCuts = [
            {
              target: testfacet1.address,
              action: 0,
              selectors: Object.keys(testfacet1.interface.functions)
              .map((fn) => testfacet1.interface.getSighash(fn),
              ),
            },
            {
              target: testfacet2.address,
              action: 0,
              selectors: Object.keys(testfacet2.interface.functions)
              .map((fn) => testfacet2.interface.getSighash(fn),
              ),
            },
          ];
          const tx = await upgradeRegistry.register(diamond.address, facetCuts, testinit.address, '0xe1c7392a');
          const initiateProposal = await tx.wait(); // 0ms, as tx is already confirmed
          const event = initiateProposal.events.find(event => event.event === 'UpgradeRegistered');
          const [diamondAddr, minimalProxyAddr, facetCutArray, initializerAddr, initializerFunc] = event.args;
          
          const registeredUpgrade = await ethers.getContractAt('UpgradeRegistry', minimalProxyAddr)
          proposalContract = registeredUpgrade.address;
        });

        it('cuts diamond via minimal-proxy proposals', async function() {
          const currentBlock = await ethers.provider.getBlockNumber();
          const timestamp = (await ethers.provider.getBlock(currentBlock)).timestamp;
  
          const deadline = timestamp + 10;
  
          await governancefacet.connect(user1).propose(proposalContract, deadline);
  
          await governancefacet.connect(user2).vote(0, true)
  
          await network.provider.send("evm_setNextBlockTimestamp", [deadline + 1])
          await network.provider.send("evm_mine");
  
          await governancefacet.executeProposal(0);
  
          // governance proposal passed
          expect(await governancefacet.proposalStatus(0)).to.equal(5);

          const testfacet1 = await ethers.getContractAt('TestFacet1', diamond.address)
          expect(await testfacet1.getInitializedValue()).to.equal(true)
        }); 

        it('proposals can mint new token supply', async function() { /// simple proposalContract example
          // predeploy proposalcontract
          const TokenMinterFactory = await ethers.getContractFactory('TokenMinter');
          const tokenminter = await TokenMinterFactory.deploy();
          await tokenminter.deployed();
          proposalContract = tokenminter.address;

          const currentBlock = await ethers.provider.getBlockNumber();
          const timestamp = (await ethers.provider.getBlock(currentBlock)).timestamp;
          const deadline = timestamp + 10;

          await governancefacet.connect(user1).propose(proposalContract, deadline);

          await governancefacet.connect(user2).vote(1, true)

          await network.provider.send("evm_setNextBlockTimestamp", [deadline + 1])
          await network.provider.send("evm_mine");

          await governancefacet.executeProposal(1);

          // governance proposal passed
          expect(await governancefacet.proposalStatus(1)).to.equal(5);

          // check that new tokens were minted
          expect(await tokenfacet.totalSupply()).to.be.above(1500)
        });
      });
    });
  });
});
