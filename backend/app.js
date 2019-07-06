const express = require('express')
const bp = require('body-parser')
const app = express()
const axios = require('axios')
const WebSocket = require('ws')

axios.defaults.headers.common['Authorization'] = `Bearer ${process.env.JWT}`
const host = process.env.APIURL.replace(/(^\w+:|^)\/\//, '')

app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));

app.post('/barker/user', async (req, res) => {
    console.log(`Request from ${req.connection.remoteAddress} to create user "${req.body.name}"`)
    
    // Create database user
    var doing = null;
    try {
        doing = 'Create user'
        var CreateUserRes = await axios.post(
            `${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/_admin/user`, {
            active: true,
            extra: {},
            passwd: req.body.passwd,
            user: req.body.name
        })

        // Todo: Grant permissions to collections
    
        // Create a stream for the users feed
        doing = 'Create stream'
        CreateStreamRes = await axios.post(
            `${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/streams/persistent/stream/${req.body.name}`, {
                outputTriggers: {}
            })
            
            
        // Create a document in the 'users' collection for the user
        doing = 'Create doc'
        const CreateDocRes = await axios.post(
            `${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/document/users`, {
            _key: req.body.name,
            about: req.body.about,
            avatar: req.body.avatar,
            active: req.body.active
        })
        
        return res.status(202).send(`Created user with id ${CreateDocRes.data._id}. Everything is OK!`);

    } catch( error) {
        console.log(`*** Create User Request from ${req.connection.remoteAddress} to ${doing} "${req.body.name}" failed with error: ${error.message}`)
        return res.status(501).send({what: `Failed to ${doing}`, err: error.message})
    }
  });

app.listen(process.env.PORT, () => {
    console.log(`Server is listening on ${process.env.PORT}`)
})

app.post('/barker/login', async (req, res) => {
    console.log(`Request from ${req.connection.remoteAddress} to log in user "${req.body.name}"`)
    
    try {
        // Get token
        var JwtTokenRes = await axios.post(`${process.env.APIURL}/_open/auth`, {
            tenant: process.env.TENANT,
            password: req.body.passwd,
            username: req.body.name
        })
        
        // Return token and API url's
        return res.send({
            jwt: JwtTokenRes.data.jwt,
            api: `${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}`,
            wss: `wss://${host}/_ws/ws/v2/consumer/persistent/${process.env.TENANT}/c8global.${process.env.FABRIC}/${req.body.name}/1`
        });


    } catch(error) {
        console.log(`*** Request from ${req.connection.remoteAddress} to get token "${req.body.name}" failed with error: ${error.message}`)
        return res.status(500).send({what: 'Failed to obtain token', err: error.message})
    }
  });

  app.post('/barker/bark', async (req, res) => {
    console.log(`Request from ${req.connection.remoteAddress} user "${req.body.barker}" to bark`)

    var bark = {
        barker: req.body.barker,
        barkType: req.body.type,
        bark: req.body.text,
        image: req.body.image,
        timestamp: new Date().getTime()
    }

    try {
        // TODO: Validate input

        const CreateDocRes = await axios.post(
            `${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/document/barks`, 
            bark)

        bark._key = CreateDocRes.data._key

        // Bark to followers 
        await distibuteBark(bark)

        // Bark to self
        await sendToStream(bark, bark.barker)

        // Return status
        return res.status(202).send({
            status: "OK",
            _key: CreateDocRes.data._key
            });
        
    } catch(error) {
        console.log(`*** Request from ${req.connection.remoteAddress} barker "${req.body.name}" to bark failed with error: ${error.message}`)
        return res.status(500).send({what: 'Failed to bark', err: error.message})
    }
  })

async function distibuteBark(bark) {
    console.log(`Distributing bark ${bark._key}`)

    const url = `${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/cursor`;
    const query =  `with users
    for follower in 1..1 inbound 'users/${bark.barker}' follow
        filter follower.active == true
        return distinct follower._key`
    
    // console.log(`url: ${url}`)
    // console.log(`query: ${query}`)


    const followersRes = await axios.post(url, {query: query})

    // TODO: Do we need to handle followersRes.data.hasMore ?
    for (ix in followersRes.data.result) {
        var name = followersRes.data.result[ix]
        console.log(` .. barking to ${name}`)

        await sendToStream(bark, name)
    }
}

async function sendToStream(bark, name) {
    let promise = await new Promise((resolve, reject) => {

        var streamUri = `wss://${host}/_ws/ws/v2/producer/persistent/${process.env.TENANT}/c8global.${process.env.FABRIC}/${name}`

        console.log(`  ... Stream: ${streamUri}`)
        
        var ws = new WebSocket(
            streamUri, {
                headers: {
                    Authorization: `Bearer ${process.env.JWT}`
                }
            })
        
        ws.on('open', () => {
            console.log("..")

            var payload = {
                payload: Buffer.from(JSON.stringify(bark)).toString('base64'),
            }

            var pstr = JSON.stringify(payload)
            console.log(`  ... Payload: ${pstr}`)

            ws.send(pstr, (err) => {
                if (err) {
                    console.log(`Failed to bark to ${name}: ` + JSON.stringify(err))
                    reject(JSON.stringify(err))
                } else {
                    resolve();
                }
            })
        })

        ws.on('message', (message) => {
            console.log('received: %s', JSON.stringify(message));
            ws.close()
        });
    })
    return promise
}