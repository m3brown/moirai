# Moirai

**Description**:  An API to create and manage AWS instances, written in Node.js.

  - **Origin of the name**: In Greek mythology, Moirai were the three Fates that controlled the thread of life.

  - **Technology stack**: Written in Node.js and utilizing the aws-sdk along with CouchDB, utilizes the [Pantheon-Helpers](https://github.com/cfpb/pantheon-helpers) platform.  Will work standalone but was developed to work alongside [Kratos](http://github.com/cfpb/kratos)
  - **Status**:  Alpha

## Dependencies

This application requires Node.js as well as the dependencies specified in [package.json](package.json)

## Installation

1. Install the application and its dependencies

```
git clone https://github.com/cfpb/moirai
cd moirai
npm install -g coffee-script
npm install
```

## Configuration

The configuration for Moirai is split into two files: `config.coffee` and `config_secret.coffee`.  The purpose of the secret file is to prevent accidentally committing confidential information such as passwords and access keys.  Any config settings and go in either config file, and settings in `config_secret.coffee` will override settings in `config.coffee`.

1. Copy the secret configs example and edit accordingly (see the Configuration section below)

```
cp src/config_secret.coffee.example src/config_secret.coffee
```

2. Adjust the configuration settings (src/config.coffee) if necessary
3. Compile the changes

```
cake build
```

## Usage

1. Update the `config.settings` and `config_secret.coffee` settings for your CouchDB server (see Configuration above)
2. Push the CouchDB configs to the CouchDB server

```
cake sync_design_docs
```

2. Start the API and the backend workers

```
cake runtestserver
cake runworker
```

## How to test the software

```
cake test
```

## Known issues

This project is still under active development and is not ready for general use

## Getting help

If you have questions, concerns, bug reports, etc, please file an issue in this repository's Issue Tracker.

## Getting involved

Please feel free to fork this repo and submit Pull Requests with any enhancements.


----

## Open source licensing info
1. [TERMS](TERMS.md)
2. [LICENSE](LICENSE)
3. [CFPB Source Code Policy](https://github.com/cfpb/source-code-policy/)


----

## Credits and references

1. [AWS-SDK for Node.js](http://aws.amazon.com/sdk-for-node-js/)
