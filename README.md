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

1. While some important things are handled automatically (limited cards, oshi skills, collabing, proper blooming), the game is by and large a manual simulator. You can find (our best translation of) the rules at https://docs.google.com/spreadsheets/d/1IdaueY-Jw8JXjYLOhA9hUd2w0VRBao9Z1URJwmCWJ64/edit?gid=408156797#gid=408156797.
2. You can also connect directly with the hosting player sharing their IP address with the joining player. ONLY GIVE YOUR IP ADDRESS TO SOMEONE YOU PERSONALLY KNOW AND TRUST. The hosting player will also have to set up port forwarding on port 25565 (yes, the minecraft port) with TCP/UDP (might be listed as “Both” in the menu).
3. The better use of "Connect with IP" is to play a local game against yourself. Open two instances, "Connect with IP" on both, "Host" on one, "Join" and then hit enter on the other.
4. Regardless, it’s recommended to play with a friend as there are obvious ways to cheat.
5. The decks are stored in an external directory. There's a "deck location" button in the info screen on the main menu that'll tell you where. Shouldn't be necessary.
6. The text box in the deck creation menu sets the deck’s name, which is what will appear in the “Choose Deck” dropdown menu.
7. MAC: MagnaDrake got a Steam error "Could not determine Steam client install directory." They had to redownload Steam. Not sure what that was about.
8. Several shout outs for community efforts in the info screen on the main menu.


Adding cards to cardData.db

**THIS IS ALL OUT OF DATE AS OF 1.1.3 AND I AM USING A CUSTOM PROGRAM TO ADD CARDS. WILL BE MADE MORE PUBLIC IN THE FUTURE**

I tend to use DB Browser for SQLite (https://sqlitebrowser.org/) to modify the db file, but anything works probably. IF USING DB BROWSER, keep in mind that it will not automatically save your changes. You have to press “Write Changes” or Ctrl+S.

Tables:

cardTypes, colors, holomemNames, supportTypes, and tags are all constant tables. The only ones that might need to be modified are supportTypes and tags as new support subtypes or tags could still be revealed. Don’t worry; I’ll do that if it comes up.

Every card needs an entry in mainCards and at least one entry in cardHasArt to appear in game. Depending on the type of card, the next steps vary.

mainCards:
>_cardID_ is the number, i.e. hBP01-001, hSD01-001,etc.

>_cardName_ is the English name of the card

>_cardType_ must be one of “Holomem”, “Oshi”,  “Support”, or “Cheer”

>_cardText_ is the English text of the card. I tend to just grab this from ogbajoj’s spreadsheet

>_cardLimit_ is the number of copies allowed in a deck (default 4). -1 for no limit.

>_jpName_ is the Japanese name of the card

_jpText_ is the Japanese text of the card. I tend to do a convoluted method that’s a mix of grabbing google translate’s best attempt at the text and painstakingly recreating the text with that and some template text I have saved. If you have a better method, _please tell me_.
When adding your own card, you can ignore the name and text options for the language you don’t care about.

cardHasArt:
>_cardID_ is checked against the same field in mainCards

>_art_index_ is used when a card has alt arts. 0 for base, 1 for first alt, 2 for second alt, etc.

>_unrevealed_ is either 0 or 1. 0 if the card was officially revealed, 1 if not (only in print)

>_art_ stores the actual card art (dimensions must be around 309x429)

In DB Browser, don’t try to put the image in directly when making the row. Make the row with art null, scroll down to the row, and click the NULL in the field. On the right, in the edit database cell portion, change the mode from Text to Image, then Import from File (the folder looking button), select the image, and hit Apply


**IF ADDING HOLOMEM**:

holomemCards:
>_cardID_ is checked against the same field in mainCards

>_level_ is 0 for debut, 1 for 1st bloom, 2 for 2nd bloom, and -1 for SPOT

>_hp_ is the max hp of the holomem

>_buzz_ is either 0 or 1. 1 if the card is a buzz holomem, 0 otherwise.

>_batonPassCost_ is the number of cheer to discard for baton pass. Can be 0

_buzz_ and _batonPassCost_ only affect description.
 
holomemHasColor:
>_cardID_ is checked against the same field in holomemCards

>_color_ is either White, Green, Red, Blue, Yellow, or Purple

If a holomem has multiple colors (like SorAz), add multiple rows, one for each color. If a holomem is colorless, add no rows. Currently only affects description.

holomemHasName:
>_cardID_ is checked against the same field in holomemCards

>_name_ is the full English name of the holomem

If a holomem has multiple names (like SorAz), add multiple rows, one for each name. Affects bloom logic.

holomemHasTag:
>_cardID_ is checked against the same field in holomemCards

>_tag_ is the English name of the tag

If a holomem has multiple tags (all so far), add multiple rows, one for each tag. Currently only affects description.


**IF ADDING OSHI**:

oshiCards:
>_cardID_ is checked against the same field in mainCards

>_life_ is… life.

All fields required.

oshiHasColor:
>_cardID_ is checked against the same field in oshiCards

>_color_ is either White, Green, Red, Blue, Yellow, or Purple

If an oshi has multiple colors, add multiple rows, one for each color. If an oshi is colorless, add no rows. Currently only affects description.

oshiHasName:
>_cardID_ is checked against the same field in oshiCards

>_name_ is the full English name of the oshi

If an oshi has multiple names, add multiple rows, one for each name. Only affects description if it doesn’t match the card name.

oshiHasSkill:
>_cardID_ is checked against the same field in oshiCards

>_skillName_ is the English name of the oshi skill

>_cost_ is the amount of holopower required. If the cost is X, set to -1.

>_sp_ is either 0 or 1. 1 if this is an SP oshi skill, 0 otherwise.

>_jpName_ is the Japanese name of the oshi skill

The game reads this table to add the skills to the dropdown menu when you click your oshi to pay the costs and keep track of opt/opg automatically. You can ignore the name field of the language you don’t care about.


**IF ADDING SUPPORT**:

supportCards:
>_cardID_ is checked against the same field in mainCards

>_supportType_ is either Item, Staff, Event, Tool, Mascot, or Fan

>_limited_ is either 0 or 1. 1 if the card is limited, 0 otherwise.

_supportType_ only affects description.


**IF ADDING CHEER**:

cheerCards:
>_cardID_ is checked against the same field in mainCards

>_color_ is either White, Green, Red, Blue, Yellow, or Purple

Currently does literally nothing. Will likely actually matter after the first major update.
