const express = require('express')
const bp = require('body-parser')
const app = express()
const axios = require('axios')

axios.defaults.headers.common['Authorization'] = `Bearer ${process.env.JWT}`

app.use(bp.json());
app.use(bp.urlencoded({ extended: true }));

app.post('/barfer/user', (req, res) => {
    var body = req.body
    console.log(`Request from ${req.connection.remoteAddress} to create user "${req.body.name}"`)
    
    // Create database user
    axios.post(`${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/_admin/user`, {
        "active": true,
        "extra": {},
        "passwd": req.body.passwd,
        "user": req.body.name
    }).then(function (CreateUserRes) {
        // Create a stream for the users feed
        axios.post(`${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/streams/persistent/stream/${req.body.name}`, {
            outputTriggers: {}
        }).then(function (CreateStreamRes) {
            // Create a document in the 'users' collection for the user
            axios.post(`${process.env.APIURL}/_tenant/${process.env.TENANT}/_fabric/${process.env.FABRIC}/document/users`, {
                _key: req.body.name,
                about: req.body.about,
                avatar: req.body.avatar,
                active: req.body.active
            }).then(function (CreateDocRes) {
                return res.status(202)
                    .send(`Created user with id ${CreateDocRes.data._id}. Everything is OK!`);
            }).catch(function (error) {
                console.log(`*** Request from ${req.connection.remoteAddress} to create user doc "${req.body.name}" failed with error: ${error.message}`)
                return res.status(500).send({what: 'Failed to create user doc', err: error.message})
            });
        }).catch(function (error) {
            console.log(`*** Request from ${req.connection.remoteAddress} to create user stream "${req.body.name}" failed with error: ${error.message}`)
            return res.status(500).send({what: 'Failed to create user stream', err: error.message})
        });
    }).catch(function (error) {
        console.log(`*** Request from ${req.connection.remoteAddress} to create user "${req.body.name}" failed with error: ${error.message}`)
        return res.status(500).send({what: 'Failed to create database user', err: error.message})
    });
  });

app.listen(process.env.PORT, () => {
    console.log(`Server is listening on ${process.env.PORT}`)
})
