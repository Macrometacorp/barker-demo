/* Simple boostrap script that creates the collections
 * and indexes required by barker.
 *
 * Use environment variables to point to the
 * correct url and to use your credentials. 
 */

const c8 = require('jsc8')

const c8Url = process.env.APIURL || 'try.macrometa.io'
const tenant = process.env.TENANT || '_mm'
const user = process.env.C8USER || 'root'
const fabricName = process.env.FABRIC || '_system'

bootstrap().then(success => console.log("Done: %s", success ? "OK" : "Failed"))

async function bootstrap() {

    try {

        const fabric = new c8.Fabric(`https://${c8Url}`);
        console.log(`Logging in to ${c8Url} as ${tenant}.${user}`);

        var what = 'login'
        await fabric.login(tenant, user, process.env.PASSWORD);

        console.log(`Using tenant ${tenant} on fabric ${fabricName}`);
        fabric.useTenant(tenant)
        fabric.useFabric(fabricName);

        console.log("Creating collection");
        what = 'create barks'
        barksCollection = fabric.collection('barks');
        await barksCollection.create();

        what = 'create follow'
        followCollection = fabric.edgeCollection('follow')
        await followCollection.create()

        what = 'create loations'
        locationsCollection = fabric.collection('locations');
        await locationsCollection.create()
        await locationsCollection.createGeoIndex('location', {geoJson: true})

        what = 'create users'
        usersCollection = fabric.collection('users');
        await usersCollection.create()

    } catch( error) {
        console.log(`Bootstrapping failed at ${what} with error: ${error.message}`)
        return false
    }

    return true
}