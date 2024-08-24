# holoDelta
An unofficial Hololive TCG simulator, worked on in my spare time

Quick notes:

1.While some important things are handled automatically (limited cards, oshi skills, collabing, proper blooming), the game is by and large a manual simulator. I will not even attempt to make it automatic until the entire first set is out. Also, school’s starting back up soon, so I will likely be too busy to work on it more than sparingly.

2.You can zoom in and out and pan the camera with a middle mouse click & drag. I don’t like this system, it is first on the chopping block. I realized this very recently, and it would take a few days to make it static.

3.Before a game can start, you must pick a deck by clicking “Choose Deck” and selecting from the dropdown menu. It only comes packaged with the starter deck.

4.There are two methods to connect with a friend to play. The suggested method is with steam. Both players need to be friends on Steam for this to work. Both players click “Connect with Steam.” It will say you’re playing Spacewar. This is normal. One player clicks “Host”, and then the other player clicks “Join” and then selects the steam name of the friend they’re trying to play with. The “Join Game” action through the steam menu is untested and likely doesn’t work.

5.You can also connect directly with the hosting player sharing their IP address with the joining player. ONLY GIVE YOUR IP ADDRESS TO SOMEONE YOU PERSONALLY KNOW AND TRUST. The hosting player will also have to set up port forwarding on port 25565 (yes, the minecraft port) with TCP/UDP (might be listed as “Both” in the menu).

6.Regardless, it’s recommended to play with a friend as there are obvious ways to cheat.

7.The game appears blank for the host player until the joining player joins. This is normal.

8.I have allowed blooming debut-to-debut. If you think this is wrong (like I do), simply don’t.

9.In the deck creation menu, the first time you open the file dialog, it will start somewhere wild. You must navigate to the “Decks” subfolder in the folder with the executable. It should open there everytime after. I’m sorry I couldn’t do that first step in code; the things you’d think would work don’t work.

10.The deck json files must be in said “Decks” subfolder to be recognized by the game.

11.The text box in the deck creation menu sets the deck’s name, which is what will appear in the “Choose Deck” dropdown menu.

12.The cardData.db file contains all the information about the cards. This is external so that new cards can be added without re-exporting the entire game.

13.I am sure there will be glitches. These could be graphical, these could be connection related, these could be cards just having the wrong data, these could be rules or mechanics I’ve misinterpreted, etc. Let me know; I’ll compile a list.

14.The first update I have planned and want to do will add nothing (or very little) to the game, but instead make it look/sound better and have more conveniences. If I did that first, it never would’ve been made.

15.I have to give thanks to the spreadsheet maintained by ogbajoj, without which this would not have been possible. Also, I have to shout out Cyber for the name holoDelta and the awesome logo.
