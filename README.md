# holoDelta
An unofficial Hololive TCG simulator, worked on in my spare time.

## Quick start

Try the game now at https://holodelta.azurewebsites.net/game/index.html!

To setup and run the web server locally:
```bash
git clone https://github.com/GabeJWJ/holoDelta.git
cd holoDelta/ServerStuff
python -m pip install -r requirements.txt
uvicorn server:app --reload
```

Notes for setting up:
- For running your own version of the server, all you need is in the "ServerStuff" folder, with the exception of a "holodelta_web" folder containing a web export of the project. DO NOT EXPORT WITH DEBUG.
- Change the "websocketURL" in server.gd to wherever you're running your local server.
- You may need to set "WebSocket" in "board" to not use WSS.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). **I am committed to accepting and encouraging community contributions!** The code is a mess. I am sure it is needlessly confusing and wildly inconsistent in style and format.

If you are interested in contributing but are confused by the code, please message me on Discord. I can be found on the [Hololive OCG Fan Server](https://discord.com/invite/dDCpFMMENM).

## Bounty

I am putting out a $100 bounty on someone going in and dealing with some annoying azure blob storage stuff for me.

I am trying to return to an app version, but this requires a method of easily updating the card information. I can get it all in a ~60 MB file, but then getting it to people is a pain. Learning from the DB, I don't want to put it in the github repo to be downloaded from there. What I want to do is keep it in Azure Blob Storage and have a link on the holoDelta site pass it through. I have a bit of code trying to make that happen, but it doesn't work for me.

Lines 41-53 in ServerStuff/Server.py, all of ServerStuff/utils/azure_blob_storage.py, and line 277 in Scripts/Multiplayer.gd

To test it, you'll probably need your account greenlisted by my azure blob storage... thing. Message me on Discord so we can talk about it.

It's probably really easy, but I don't have the motivation to figure it out. It would probably take me another month or two to do myself and I'd much rather just pay someone to do it for me so I can focus on adding features to the sim which I actually like and am good at.

This is a genuine offer, though I must admit I don't know how I'd get it to you. I don't have PayPal or the like. We can discuss it.