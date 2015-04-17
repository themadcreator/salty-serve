
# Salty Server

Securely serve up files over HTTP. Files can be downloaded by anyone that can
access the server, but only the client with the keys can decrypt them.


# How to

### Install salty-serve

On both client and server, run:

    npm install -g salty-serve

If you do not have permissions to install globally, you can still run everything through node_modules:

    npm install salty-serve
    node_modules/salty-serve/bin/salty-keygen
    node_modules/salty-serve/bin/salty-serve
    node_modules/salty-serve/bin/salty-decrypt

#### Generate keys

This will generate both client and server keys. Keep the client keys safe.

    salty-keygen

#### Start salty-serve

Copy `server-keys.json` to the server. Then, from the directory you want to serve, run:

    salty-serve -p 1111 -k server-keys.json .

#### List all files

Navigate your browser to the server, or use a commandline utility like curl:

    curl -s http://localhost:1111

#### Download and decrypt all files

This command will get the list of all files from the salty-serve, then one-by-one will download, unzip, and decrypt them

    curl -s http://localhost:1111 | xargs -I filename sh -c "curl -s http://localhost:1111/filename | gunzip | salty-decrypt -k client-keys.json > filename"


# Details

Uses NaCl's crypto_box encoded as hexstrings in JSON and then gzipp'ed for HTTP transport.