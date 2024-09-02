# holoDelta
An unofficial Hololive TCG simulator, worked on in my spare time

Quick start:
1. Download the "holodelta_linux.zip", "holodelta_windows.zip", or "holodelta_mac.zip" over in releases, based on your OS
2. LINUX & WINDOWS: Simply extract the folder somewhere and run "holodelta.x86_64" or "holodelta.exe"
3. MAC: Be glad this even kinda works. Extract "holodelta.app" from the zip file.
4. MAC: The app is unsigned and unnotarized, so you'll have to open a terminal at the folder containing the app and run xattr -dr com.apple.quarantine "holoDelta.app"
5. Before a game can start, you must pick a deck by clicking “Choose Deck” and selecting from the dropdown menu. It only comes packaged with the starter deck.
6. The suggested connection method is with steam. Both players need to be friends on Steam for this to work.
7. Both players click “Connect with Steam.” It will say you’re playing Spacewar. This is normal.
8. One player clicks “Host”, and then the other player clicks “Join” and then selects the steam name of the friend they’re trying to play with. The “Join Game” action through the steam menu is untested and likely doesn’t work.

Quick notes:

1. While some important things are handled automatically (limited cards, oshi skills, collabing, proper blooming), the game is by and large a manual simulator. You can find (our best translation of) the rules at https://docs.google.com/spreadsheets/d/1IdaueY-Jw8JXjYLOhA9hUd2w0VRBao9Z1URJwmCWJ64/edit?gid=408156797#gid=408156797. I will not even attempt to make it automatic until the entire first set is out. Also, I'm back in school, so I will likely be too busy to work on it more than sparingly.
2. You can zoom in and out and pan the camera with a middle mouse click & drag. I don’t like this system, it is first on the chopping block. I realized this very recently, and it would take a few days to make it static.
3. You can also connect directly with the hosting player sharing their IP address with the joining player. ONLY GIVE YOUR IP ADDRESS TO SOMEONE YOU PERSONALLY KNOW AND TRUST. The hosting player will also have to set up port forwarding on port 25565 (yes, the minecraft port) with TCP/UDP (might be listed as “Both” in the menu).
4. The better use of "Connect with IP" is to play a local game against yourself. Open two instances, "Connect with IP" on both, "Host" on one, "Join" and then hit enter on the other.
5. Regardless, it’s recommended to play with a friend as there are obvious ways to cheat.
6. The game appears blank for the host player until the joining player joins. This is normal.
7. I have allowed blooming debut-to-debut. If you think this is wrong (like I do), simply don’t.
8. The decks are stored in an external directory. A tiny "info" button on the bottom left of the main menu will tell you where.
9. The save/load file dialogs tend to not actually start there. These are also on the chopping block.
10. The text box in the deck creation menu sets the deck’s name, which is what will appear in the “Choose Deck” dropdown menu.
11. The cardData.db file contains all the information about the cards. This is external so that new cards can be added without re-exporting the entire game.
12. MAC: The cardData.db file is inside the Contents/MacOS folder _inside_ the App. I was unaware that was a thing.
13. MAC: MagnaDrake got a Steam error "Could not determine Steam client install directory." They had to redownload Steam. Not sure what that was about.
14. Huge shoutouts to Cyber for the name and logo, MagnaDrake for the help with the Mac release, hinanjo for the JP help, and ogbajoj without whose spreadsheet this would not have been possible.
