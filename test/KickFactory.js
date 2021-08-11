const { expect } = require("chai")

describe("KickFactory contract", function () {

    let KickFactory
    let hardhatKickFactory
    let owner
    let addr1
    let addr2
    let addrs
    const sleep = function(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    beforeEach(async function () {
        KickFactory = await ethers.getContractFactory("KickFactory")
        ;[owner, addr1, addr2, ...addrs] = await ethers.getSigners()
        hardhatKickFactory = await KickFactory.deploy()
    })

    it("should start with no projects", async function () {
        expect(await hardhatKickFactory.numProjects()).to.equal(0)
    })

    it("should create 1 project on calling launchProject", async function () {
        await hardhatKickFactory.launchProject(0, 0, 0)
        expect(await hardhatKickFactory.numProjects()).to.equal(1)
    })

    it("should create 1 more project on subsequent call to launchProject", async function () {
        await hardhatKickFactory.launchProject(0, 0, 0)
        await hardhatKickFactory.launchProject(0, 0, 0)
        expect(await hardhatKickFactory.numProjects()).to.equal(2)
    })

    describe("KickProject contract", function () {
        it("should be created with correct goal and draw down interval", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 60)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            expect(await hardhatKickProject.goal()).to.equal("60000000000000000")
            expect(await hardhatKickProject.drawDownInterval()).to.equal(60)
        })

        it("should accept contributions", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 60)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "60000000000000000"})
            expect(await hardhatKickProject.amountCollected()).to.equal("60000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal("60000000000000000")
        })

        it("should not accept contributions after timeout", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 0, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            // await sleep(1000)
            await expect(hardhatKickProject.connect(addr1).contribute({value: "60000000000000000"})).to.be.revertedWith("Project deadline has been reached")
            expect(await hardhatKickProject.amountCollected()).to.equal(0)
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal(0)
        })

        it("should not allow contribution withdrawal before timeout", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "20000000000000000"})
            await hardhatKickProject.connect(addr2).contribute({value: "20000000000000000"})
            await expect(hardhatKickProject.connect(addr1).withdrawContribution()).to.be.revertedWith("Cannot withdraw contribution, project is still open for contributions")
            expect(await hardhatKickProject.amountCollected()).to.equal("40000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal("20000000000000000")
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal("20000000000000000")
        })

        it("should not allow contribution withdrawal by non-contributor", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "20000000000000000"})
            await hardhatKickProject.cancel()
            await expect(hardhatKickProject.connect(addr2).withdrawContribution()).to.be.revertedWith("Cannot withdraw contribution, sender has not made a contribution")
            await hardhatKickProject.connect(addr1).withdrawContribution()
            expect(await hardhatKickProject.amountCollected()).to.equal(0)
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal(0)
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal(0)
        })

        it("should allow contribution withdrawal after cancellation", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "20000000000000000"})
            await hardhatKickProject.connect(addr2).contribute({value: "20000000000000000"})
            await hardhatKickProject.cancel();
            await hardhatKickProject.connect(addr1).withdrawContribution()
            expect(await hardhatKickProject.amountCollected()).to.equal("20000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal(0)
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal("20000000000000000")
        })

        it("should not accept contributions after cancellation", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.cancel()    
            await expect(hardhatKickProject.connect(addr1).contribute({value: "60000000000000000"})).to.be.revertedWith("Project has been cancelled")
            expect(await hardhatKickProject.amountCollected()).to.equal(0)
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal(0)
        })

        it("should not accept contributions after reaching funding goal", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "60000000000000000"})
            await expect(hardhatKickProject.connect(addr2).contribute({value: "60000000000000000"})).to.be.revertedWith("Project goal has been met, contributions are no longer accepted")
            expect(await hardhatKickProject.amountCollected()).to.equal("60000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal("60000000000000000")
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal(0)
        })

        it("should allow draw down after reaching funding goal", async function () {
            await hardhatKickFactory.launchProject("60000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "60000000000000000"})
            await hardhatKickProject.drawDownFunds("40000000000000000")
            expect(await hardhatKickProject.amountCollected()).to.equal("60000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal("60000000000000000")
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal(0)
            expect(await hardhatKickProject.drawnDown()).to.equal("40000000000000000")
        })

        it("should not allow draw down before reaching funding goal", async function () {
            await hardhatKickFactory.launchProject("70000000000000000", 300, 0)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "30000000000000000"})
            await hardhatKickProject.connect(addr2).contribute({value: "30000000000000000"})
            await expect(hardhatKickProject.drawDownFunds("40000000000000000")).to.be.revertedWith("Project goal has not been met")
            expect(await hardhatKickProject.amountCollected()).to.equal("60000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal("30000000000000000")
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal("30000000000000000")
            expect(await hardhatKickProject.drawnDown()).to.equal(0)
        })

        it("should not allow full draw down immediately when timed withdrawal has been requested", async function () {
            await hardhatKickFactory.launchProject("70000000000000000", 300, 100)
            const KickProject = await ethers.getContractFactory("KickProject")
            const hardhatKickProject = await KickProject.attach(await hardhatKickFactory.projects(0))
            await hardhatKickProject.connect(addr1).contribute({value: "30000000000000000"})
            await hardhatKickProject.connect(addr2).contribute({value: "40000000000000000"})
            await expect(hardhatKickProject.drawDownFunds("40000000000000000")).to.be.revertedWith("Insufficient funds available")
            await hardhatKickProject.drawDownFunds("7000000000000000")
            await expect(hardhatKickProject.drawDownFunds("100000000000000")).to.be.revertedWith("Insufficient funds available")
            expect(await hardhatKickProject.amountCollected()).to.equal("70000000000000000")
            expect(await hardhatKickProject.contributions(addr1.getAddress())).to.equal("30000000000000000")
            expect(await hardhatKickProject.contributions(addr2.getAddress())).to.equal("40000000000000000")
            expect(await hardhatKickProject.drawnDown()).to.equal("7000000000000000")
        })
    })

})

