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