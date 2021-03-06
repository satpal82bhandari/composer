/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const BusinessNetworkConnection = require('composer-client').BusinessNetworkConnection;
const BusinessNetworkDefinition = require('composer-admin').BusinessNetworkDefinition;
const fs = require('fs');
const path = require('path');
const TestUtil = require('./testutil');

const chai = require('chai');
chai.use(require('chai-as-promised'));
chai.use(require('chai-subset'));
const should = chai.should();

describe('Event system tests', function() {

    this.retries(TestUtil.retries());

    let cardStore;
    let bnID;
    let businessNetworkDefinition;
    let client;

    before(async () => {
        await TestUtil.setUp();
        // In this systest we are intentionally not fully specifying the model file with a fileName, and supplying no value in model creation
        const modelFiles = [
            { fileName: 'models/events.cto', contents: fs.readFileSync(path.resolve(__dirname, 'data/events.cto'), 'utf8') }
        ];
        const scriptFiles =  [
            { identifier: 'events.js', contents: fs.readFileSync(path.resolve(__dirname, 'data/events.js'), 'utf8') }
        ];
        businessNetworkDefinition = new BusinessNetworkDefinition('systest-events@0.0.1', 'The network for the event system tests');
        modelFiles.forEach((modelFile) => {
            businessNetworkDefinition.getModelManager().addModelFile(modelFile.contents);
        });
        scriptFiles.forEach((scriptFile) => {
            let scriptManager = businessNetworkDefinition.getScriptManager();
            scriptManager.addScript(scriptManager.createScript(scriptFile.identifier, 'JS', scriptFile.contents));
        });

        bnID = businessNetworkDefinition.getName();
        cardStore = await TestUtil.deploy(businessNetworkDefinition);
        client = await TestUtil.getClient(cardStore,'systest-events');
    });

    after(async () => {
        await TestUtil.undeploy(businessNetworkDefinition);
        await TestUtil.tearDown();
    });

    beforeEach(async () => {
        await TestUtil.resetBusinessNetwork(cardStore,bnID, 0);
    });

    let validateEvent = (event, index) => {
        event.getIdentifier().should.have.string(`#${index}`);
        if (event.$type.match(/SimpleEvent/)) {
            event.stringValue.should.equal('hello world');
            event.stringValues.should.deep.equal([ 'hello', 'world' ]);
            event.doubleValue.should.equal(3.142);
            event.doubleValues.should.deep.equal([ 4.567, 8.901 ]);
            event.integerValue.should.equal(1024);
            event.integerValues.should.deep.equal([ 32768, -4096 ]);
            event.longValue.should.equal(131072);
            event.longValues.should.deep.equal([ 999999999, -1234567890 ]);
            let expectedDate = new Date('1994-11-05T08:15:30-05:00');
            event.dateTimeValue.getTime().should.equal(expectedDate.getTime());
            let expectedDates = [ new Date('2016-11-05T13:15:30Z'), new Date('2063-11-05T13:15:30Z') ];
            event.dateTimeValues[0].getTime().should.equal(expectedDates[0].getTime());
            event.dateTimeValues[1].getTime().should.equal(expectedDates[1].getTime());
            event.booleanValue.should.equal(true);
            event.booleanValues.should.deep.equal([ false, true ]);
            event.enumValue.should.equal('WOW');
            event.enumValues.should.deep.equal([ 'SUCH', 'MANY', 'MUCH' ]);
        } else if (event.$type.match(/ComplexEvent/)) {
            event.simpleAsset.getIdentifier().should.equal('ASSET_1');
            event.simpleAssets[0].getIdentifier().should.equal('ASSET_1');
            event.simpleAssets[1].getIdentifier().should.equal('ASSET_2');
        }
    };

    afterEach(() => {
        client.removeAllListeners('event');
    });

    after(() => {
        if (client) {
            client.removeAllListeners('event');
        }
    });

    it('should emit an event in a transaction that contains primitive properties', async () => {
        this.timeout(1000);
        let emitted = 0;
        let factory = client.getBusinessNetwork().getFactory();
        let transaction = factory.newTransaction('systest.events', 'EmitSimpleEvent');

        // Listen for the event
        const promise = new Promise((resolve, reject) => {
            client.on('event', (ev) => {
                validateEvent(ev, emitted);
                emitted++;
                emitted.should.equal(1);
                resolve();
            });
        });
        await client.submitTransaction(transaction);
        await promise;
    });

    it('should emit an event in a transaction that contains complex properties', async () => {
        this.timeout(1000); // Delay to prevent transaction failing
        let emitted = 0;
        let factory = client.getBusinessNetwork().getFactory();
        let transaction = factory.newTransaction('systest.events', 'EmitComplexEvent');

        // Listen for the event
        const promise = new Promise((resolve, reject) => {
            client.on('event', (ev) => {
                validateEvent(ev, emitted);
                emitted++;
                emitted.should.equal(1);
                resolve();
            });
        });
        await client.submitTransaction(transaction);
        await promise;
    });

    it('should emit two events in a single transaction', async () => {
        this.timeout(1000); // Delay to prevent transaction failing
        let counts = [1, 2];
        let emitted = 0;
        let factory = client.getBusinessNetwork().getFactory();
        let transaction = factory.newTransaction('systest.events', 'EmitMultipleEvents');

        // Listen for the event
        const promise = new Promise((resolve, reject) => {
            client.on('event', (ev) => {
                validateEvent(ev, emitted);
                emitted++;
                emitted.should.equal(counts[emitted - 1]);
                if (emitted === 2) {
                    resolve();
                }
            });
        });
        await client.submitTransaction(transaction);
        await promise;
    });


    if (TestUtil.isHyperledgerFabricV1()) {

        // This test only works on a real fabric, because the embedded and web connectors are
        // currently broken with regards to multiple connections to the same business network.
        it('should subscribe for events without submitting a transaction', async () => {
            this.timeout(1000); // Delay to prevent transaction failing
            let emitted = 0;
            let factory = client.getBusinessNetwork().getFactory();
            let transaction = factory.newTransaction('systest.events', 'EmitSimpleEvent');

            // Listen for the event using a second business network connection
            const listenOnlyClient = new BusinessNetworkConnection({cardStore});
            await listenOnlyClient.connect('admincard');
            const promise = new Promise((resolve, reject) => {
                listenOnlyClient.on('event', (ev) => {
                    validateEvent(ev, emitted);
                    emitted++;
                    emitted.should.equal(1);
                    resolve();
                });
            });
            await client.submitTransaction(transaction);
            await promise;
        });

        // This test can only work on a real fabric where a r/w set from 2 different organisations
        // are returned and they disagree on the simulation results.
        it('should not emit an event if a transaction is not committed', async () => {
            this.timeout(1000);
            let emitted = 0;
            let factory = client.getBusinessNetwork().getFactory();
            let transactionDet1 = factory.newTransaction('systest.events', 'EmitBasicEvent');

            let transactionNonDet2 = factory.newTransaction('systest.events', 'EmitBasicEventNonDeterministic');
            let transactionDet3 = factory.newTransaction('systest.events', 'EmitBasicEvent');

            // Listen for the event
            const promise = new Promise((resolve, reject) => {
                client.on('event', (ev) => {
                    if (ev.$type.match(/BasicEvent/)) {
                        emitted++;
                        ev.nonDeterministic.should.be.false;
                        if (emitted === 2) {
                            resolve();
                        }
                    }
                });
            });

            await client.submitTransaction(transactionDet1);

            try {
                await client.submitTransaction(transactionNonDet2);
                should.fail('Should have got an endorsement policy failure');
            } catch(error) {
                error.message.should.match(/ENDORSEMENT_POLICY_FAILURE/);
            }

            await client.submitTransaction(transactionDet3);
            await promise;
        });
    }
});
