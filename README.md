# holoDelta Quick Start Guide

You can download the application at https://github.com/GabeJWJ/holoDelta/releases/latest for Windows, Mac, and Linux. The application is standalone and needs nothing else to run.

There is also a web version at holodelta.net or holodelta.azurewebsites.net (either should work but azure can be weird so try the other if one doesn’t work). The web version is not ideal for several reasons, so I recommend you use the application if you intend to use delta a lot.

If you use the Mac version, you will need to take some special steps
After extracting zip file somewhere, open a terminal at the folder containing the app and run the command    xattr -dr com.apple.quarantine "holoDelta.app"

The discord is at https://discord.com/invite/dDCpFMMENM.


# Setup

If things go smoothly, there should be no setup on your part. The application will automatically download the latest cardData.zip file to the correct location and connect to the server.

If the application fails to download the cardData.zip file, it will throw up an error and try to send you to https://github.com/GabeJWJ/holoDelta/releases/tag/CardData to manually download the file. There are instructions there, but essentially you need to download cardData.zip (not cardData.db) and place it unextracted in your “user folder.”

If the application fails to connect to the server… sorry. Try again in a bit; the server may just be updating.


# User Folder

I will refer at several points to a “user folder.” In fact, I already did so earlier. This is where the persistent files that delta needs to work correctly are stored. Where this folder is depends on your OS.

Windows: C://Users/[name]/AppData/Roaming/Godot/app_userdata/HoloDelta (May change if you remapped %APPDATA%)
Linux: ~/.local/share/godot/app_userdata/HoloDelta
MacOS: ~/Library/Application Support/Godot/app_userdata/HoloDelta

Note that you may need to enable the ability to view hidden files/folders in your file browser.

On the main menu, if you click “Info” and then “Deck Location” it will open your decks folder, which is in your user folder.

The user folder contains cardData.zip, settings.json, your decks folder, and a logs folder. Also some other weird folders Godot uses, but those are the only ones you need to worry about.

The website technically also has a user folder somewhere in your cookies, but I don’t know how to access it. There are workarounds for the things you would need.


# Updates

On the bottom right of the main menu, you can see your current Client Version and Card Version.

Client Version refers to the application itself and is notated with the 1.[Major].[Minor].[Patch] system. This will not show on the website.

Card Version refers to the database of cards that the simulator is using and is notated with the date of the last update.

When launching the application, if it detects a client update it will point you to the github page to download the latest version. I can’t overwrite the executable you’re currently running, so you have to download it yourself. If it detects a card update, it can download that itself. You may choose not to though, in case you need to quickly do something or you know you’ll have to manually download it anyway.


# Basic Settings

If you click the gear icon on the top right of the main menu, you’ll see the settings menu.

“Match Card Language” will attempt to change the card images to be in the language you have your client set to. If that’s on, “Allow Proxies” will allow for proxies to be used when an official version in your language is unavailable. That currently does very little, so don’t worry about it.

There are two separate volume sliders for the sound effects and background music.

There is a whole section to change keybindings.


# Language

The middle button in the group of three on the bottom left changes the language of the client. Note that not all languages have translated everything; it will fall back to English when it can’t find a translation.

The languages that are in delta are precisely the ones that people donate their time to. If you would like to help translate delta into your language, please DM me. I can get that set up. I can also accept proxies in different languages. Just make sure you have permission from whoever made them.


# Only EN

The English and Japanese versions of the game are (for now at least) separate with distinct cardpools and restriction lists. As such, delta can go between the two using the “Only EN” button on the main menu.

With “Only EN” enabled, you will still be able to use all of the different alt arts of each card even if they are only in Japanese. You will just only be able to use cards that are legal in EN play. This is for logistical reasons (ask about Friendly PC).

This setting changes not only what cards appear in the deckbuilder, but also what shows up in your list of decks and what lobbies/games are visible to you. This is why it’s on the main menu and not in the deckbuilder.

If you have this setting off you can still see and join “Only EN” lobbies, but they will be marked as such.


# Decks

Decks are stored in json files in the decks subfolder of your “user folder.” On the application, you can go to the main menu and click “Info” then “Deck Location” to go to this folder to share the files.

On the website it is difficult to find the actual folder, so there is an “Import/Export (WIP)” tab in the deck builder with a button to download the JSON file. It will be disabled if the deck is not legal, so please check the tooltip on the save button for current issues.

When loading a deck, if you scroll to the bottom of the list you’ll see a “Load From File” button that can load a deck from a json file. This won’t add the deck to your decks folder though; you’ll need to load the file in your deckbuilder and then save it there.

When loading a deck, each deck button has a red trash can icon in the top left. Clicking that will delete the deck.


# Deckbuilder

If you click the “Create/Edit Deck” button on the main menu, it will take you to the deck builder. There’s a lot here, so I’ll try to focus on the non-obvious parts.

Left clicking a card (either in the deck or on the rightside panel) will add a copy of that card to your deck. Right clicking it will remove a copy. The exception is oshis which can only be added, overwriting whatever oshi is currently there.

On the cheer panel, there are buttons for multipliers. This will determine how many copies will be added (resp. removed) when left (resp. right) clicking a cheer card on the side panel. Left and right clicking on the cheer in the deck will always add or remove exactly one copy.

The arrows underneath cards on the right panel will change what alternate art you’re using for the card. You can mix and match.

The searchbar will search the card’s entire raw text, including the behind-the-scenes commands that cause images to appear in the info panel. As such, there may be some strange results when searching.

If the save button is greyed out, there’s probably an issue with the legality of your deck. Hovering over the save button will display a popup with a list of reasons the deck is currently illegal.

The textbox below the deck is for the display name of the deck. This is what will appear in your list of decks when picking one to play.

When you go to save the deck, you will be given two options. You can overwrite an existing deck file by clicking on the corresponding button (you do not hit “Save”), or you can type a filename (not including the .json) in the textbox below and hit “Save.”

On the website there is an “Import/Export (WIP)” tab in the deck builder with a button to download the JSON file. It will be disabled if the deck is not legal, so please check the tooltip on the save button for current issues.


# Connection

I’ll start off this section with a preemptive apology for how bad the server connection is. The internet is not my area of expertise.

I’m hosting the server with Microsoft Azure, and it pisses me off. It has in the past just suddenly made the connection unusable for like a month with no discernible explanation.

If your connection flickers even briefly, you will be kicked from the game and be unable to rejoin. If you have an unstable internet connection, I’m sorry but it will be difficult and frustrating to use delta.

For some reason Azure has multiple instances of the server (usually just two) you can connect to even though it really shouldn’t. As such, you may not be able to see a lobby/game you know exists. In the top left of the main menu, there is a “Quick Refresh” button that will retry connecting the server, potentially connecting to the other instance. The randomly-generated instance ID is written beneath that button, so you can tell when it changes or coordinate with a friend to be sure you’re on the same instance.

I recognize that’s annoying, but I can’t stress enough that I didn’t choose this and have no control over it.

It is theoretically possible though vanishingly unlikely that both instances generate the same ID, at which point idk yell at me and I’ll restart the server.

Also, the only thing you can do without being connected to the server is build a deck.


# Loading Card Images

The most storage/memory-intensive part of delta by far is storing/loading all of the images for the cards. I would imagine this is not unusual for simulators.

Delta uses a system that will asynchronously load the card images as needed. This shouldn’t be very noticeable in-game (maybe you’ll be able to see some cards loading at the very start), but will be rather noticeable in the deckbuilder as it needs to load many cards at once. It should still be fully functional while cards are loading, but please have patience with it.

In fact the deckbuilder will only immediately load the ‘first’ art of each card when opened, saving the alt arts to only be loaded when you click over to them.

The storage issue comes into play with the website. Packaging the card images into the actual webapp will result in a deliverable that is way too large to be feasible. As such, the website does not have the card images stored and will instead attempt to download each card image from github as needed. This will be much more noticeable than the loading on the app version, so please be patient.

The website will attempt to store these downloaded images in your cookies for quick use later on, but this repository will have to be deleted every time the card database updates. This is because images get updated rather regularly and there is no mechanism to sort out which ones were updated.


# How To Play The Hololive OCG

I mean, I should cover my bases.

You can find the official rule book at https://en.hololive-official-cardgame.com/wp-content/themes/tcg_en/assets/img/rule/official_rule_book_ver1_02.pdf (it is remarkably thorough – I approve).

For a quick overview, you can look at the quick manual at https://en.hololive-official-cardgame.com/wp-content/themes/tcg_en/assets/img/rule/quick_manual_260507.pdf.

If you prefer to watch a video to see the game more in action, you can check out the official caravan learning video narrated by Kiara at https://www.youtube.com/watch?v=_-9QjVI7vcg.

That video is kind of slow-paced because of the context it was presented in though, so you may prefer Liam of Weiss And Chill’s video at https://www.youtube.com/watch?v=ebk0F7vsalU.

On the other end of the spectrum would be my own video that spends the first ~40 minutes on a very thorough overview of how to play the game (including a full sample game) addressing as many common confusions as I could at https://www.youtube.com/watch?v=3T2tVYqvGvo. I’ll be the first to admit though that I may have overdone it and it’s kind of hard to follow without a baseline understanding.

Also, all three of the videos are outdated because there were some rule changes. Your oshi cards are revealed to your opponent from the very start of the preliminary phase, and the mulligan rules were changed (for the better). Refer to the official rule book for the new mulligan system.


# Online Play

The stack of buttons in the center of the main menu are related to actually playing a game.

The text field at the top sets your in-game name. There is no account syncing or username reservation.

“Create Lobby” takes you to a menu to select options for hosting a new lobby. The “Private” toggle will make it so that the lobby doesn’t appear in the “Join Lobby” menu and must be joined directly. The “Allow Public Spectators” toggle will make it so that the game you eventually create will appear in the “Spectate Game” menu. The “Banlist” dropdown will select what banlist both you and your opponent will be beholden to.

“Join Lobby” takes you to a menu to join an existing lobby. You can click on any public lobby to join it, or you can enter the code of a private lobby in the text field at the bottom and click “Join Lobby” (or press Enter).

“Spectate Game” takes you to a menu to spectate an existing game. You can click on any publicly-viewable game to spectate it, or you can enter the code of a game in the text field at the bottom and click “Spectate Game” (or press Enter). You find the code of a game you’re part of by going to the settings tab on the sidebar.

Delta currently does not offer matchmaking. Please play with friends or find someone to play with using the #lfg channel in the discord.


# Navigating A Lobby

The lobby menu is split into two parts. On the right, you have the lobby code to share for private lobbies and the list of potential opponents. The host can choose one to battle. On the left, you and your opponent can select decks and ready up. If your chosen deck isn’t legal, you will get a message back from the server explaining what the problem is. The host can choose a new opponent even after their current one readies up.

Once both players have chosen their decks and readied up, the host can press “Start Game” on the bottom right to begin. Any unchosen players will be given a prompt to spectate the game if “Allow Public Spectators” was selected when creating the lobby.


# Banlists

The hololive OCG does not currently have a ‘banlist’ so to speak, but it does have a restriction list of cards that are restricted to one copy. This can change over time and be different between versions (EN and JP).

There are also regularly cards in holoDelta that have not actually been released yet (as there is a lengthy spoiler season before a new set comes out).

The “Current” banlist enforces the restriction list and forbids using any unreleased cards. The “Current + Unreleased” banlist only enforce the restriction list but permits unreleased cards. The “Current (EN)” and “Current + Unreleased (EN)” banlists do the same but for the EN format. Although the latter has yet to be different from the former.


# Goldfishing

In the context of trading card games, the word “goldfish” as a verb means to play a game with just one deck (or with an impotent opponent). The purpose is usually to test that one deck, going through the motions to see what thresholds it is or isn’t hitting and labbing out combos/interactions.

You can press the “Goldfish” button on the main menu to do this in delta. You select a deck and then play against an empty field. Every time you end your turn, your “opponent” immediately passes.

You can click on any of the opponent’s zones to add damage to them to simulate the outcomes of your attacks/effects. Hovering over a zone will show you a turn-by-turn breakdown of marginal/total damage to see what thresholds you’re hitting.

You can also add notes to the opponent’s zones to denote things like critical hit damage or non-damage effects.

I’m not really sure what goes into a good goldfish mode, so feel free to suggest improvements.


# Starting A Game

When you get into a game with an opponent, you will play rock-paper-scissors until a winner is determined. Then the winner will decide whether they would like to go first or second.

Then starting hands are dealt and the mulligan process begins. After all mulligans are done, your opponent will see all of the cards you were forced to mulligan. This is a notable departure from Real Play where you have to show your hand each time you do a forced mulligan.

You must place a debut holomem in the center position by clicking on one in your hand and selecting “Place facedown in center.” If you needed to do forced mulligans, you must click on cards in hand and select “Send to bottom of deck.” You may place up to 5 more debuts/spots to the back by clicking on them in your hand and selecting “Place facedown in back.”

After this, you may press the “Ready” button. After both players ready up, the game begins with the first player’s first turn.


# holoDelta Is (Mostly) Manual

Delta is not an automated simulator. There are many alternative simulators in #fan-projects on the discord if that is non-negotiable.

Delta is also not a fully manual simulator where “cards is cards” and you just have a few generic options with the game not knowing any rules for itself. To cut this off at the pass, it is very non-trivial to turn delta into such a simulator (even as just an option).

The guiding principle of holoDelta is that it will do as much as it can without taking into account any of the text on the card. This is more than you may think at first blush.

To get to the point, holoDelta is a manual simulator. If you play Harusaki Nodoka (hSD01-016), then holoDelta will not draw 3 cards and archive the Nodoka. You will need to click on your main deck, select “Draw X” from the popup, and type in ‘3’ for X in the window that appears. Then you will have to click the Nodoka in the resolution zone and select “Archive” from the popup.

However, there are many aspects of the game that holoDelta will take care of by itself. If you click a back holomem and select “Collab” from the popup, then that holomem will go to the collab position and the top card of your main deck will be placed into holopower facedown automatically. If that holomem is rested, or you’ve already collabed once that turn, or your main deck is empty, then the option to “Collab” will not appear.

Similarly, the command to “Play” a limited support card will not appear if it is the first player’s first turn or you’ve already used a limited card that turn.

There are also commands that get around these limitations, like “Move to collab position” and “Play (anyway).”

The “Bloom” command will take all of the blooming restrictions (Name, level, HP, played this turn) into account when giving you your options. Unless, of course, you use one of the commands that bypasses some of these restrictions.

If one of the victory conditions is met, a window will ask the losing player if they truly did lose to that victory condition (since mistakes can happen). Selecting “Yes” will end the game.


# Info Panel

The Info Panel is on the left of the screen in-game and in the deckbuilder. Hovering over a card will show that card’s information on the info panel. The majority of what’s shown is self-explanatory.

If the card has attachments (or was bloomed on top of other cards), they will be presented in a stack that you can switch between using the mouse wheel. This is with the notable exception of any cheer attached, which are instead represented with a row of icons below the card image. Note that you can click on a holomem (even an opponent’s holomem) and select the “Look at attached” or “Look at past blooms” command to get a better look at these cards and potentially take actions with them.

You can ‘lock’ the card shown on the info panel with a keybind (default CTRL) until you use the keybind again. The imagined use case for this is when a card has too much text to be displayed all at once, so you need to move your mouse over to the info panel and scroll. If another card is in the way, that could be annoying without a lock button. There is a lock icon on the info panel that will change opacity when frozen.


# Communication

Being a manual simulator, you will need to communicate with your opponent to properly play the game (although I have attempted to minimize the necessity). The best method to do this will always be to be in a separate voice chat with your opponent, but there are a few tools in-game to assist with this.

Most notably, there is a chat feature in the sidebar. You can switch between the chat panel and the info panel by pressing the buttons on the side or using a keybind (default TAB). This chat panel also contains a game log of all actions taken by both players. A red circle will appear on the chat panel button if your opponent sends you a message while you’re on a different panel.

There is a phase tracker on the sidebar, and you can click between the different phases. These don’t do anything mechanically, but they can help make what you’re doing clearer to your opponent. There are keybinds (default [ and ]) to go between them. Keep in mind that going to the next phase while on the end phase will pass the turn.

Also, if you click on a card on the stage a brief animation will play of a flicker black border around that card. This is visible to your opponent, and can be used to single out a card without having to verbally describe it. I will admit the effect is a bit subtle though.


# Non-obvious Commands

The majority of commands in holoDelta are – I believe – rather self-explanatory. The “Draw” command draws a card from the main deck, the “Play” command plays a card from hand, the “Shuffle hand into deck” command puts all cards in your hand into the main deck and then shuffles it, et cetera. Some however are not so easily understood.

There are many cards that subvert the usual rules to blooming/playing holomem, and so new commands needed to be made for them. A level 1 or 2 holomem will have a “Play directly” command that places that holomem directly onto the stage without needing to bloom them on top of another holomem. The “Instant bloom” command will bloom the chosen holomem onto a holomem that was played/bloomed that very turn. The “Skip bloom” command will bloom the chosen level 2 holomem directly onto a debut instead of a level 2 holomem.

If you click a holomem bloomed on top of another, you can select the “Unbloom” command to pick that holomem up back into your hand and leave the previous holomem still on the field.

We had issues in the past with people accidentally clicking the “Shuffle hand into the deck” command, so the “Unshuffle hand into deck” command was created to be able to undo that action. Note that taking any action that messes with the contents of the main deck will remove your ability to use this command, making the “Shuffle hand into deck” command permanent.

Clicking the main deck and selecting the “Play RPS” command will challenge your opponent to a game of Rock-Paper-Scissors. 


# Keybinds

There are a series of keybinds that can make certain game actions more convenient. The vast majority of these are rebindable in the options menu on the main menu.

The only non-rebindable shortcut is that right-clicking one of your holomem will rest/unrest it.

There is a keybind (default D) to draw a card from the main deck. Does not work if the main deck is empty.

There is a keybind (default C) to reveal the top card of your cheer deck and go straight into the menu to select a holomem to attach it to.

There is a keybind (default R) to do an entire standard reset phase. As in, it will unrest all of your holomem and then move your collab holomem to the back and rest it. This one is a serious timesaver.

There is a keybind (default TAB) to switch between the info panel and chat panel.

There is a keybind (default CTRL) to lock/unlock the info panel.

There is a keybind (default [) to return to the previous phase in the phase tracker. It will do nothing if used on the first phase of the turn.

There is a keybind (default ]) to go to the next phase in the phase tracker. It will pass the turn if used on the end phase.


# Cosmetics

Delta supports using custom images for card sleeves, the playmat, the die, and the SP marker.

Each deck can have custom images set separately for the main deck sleeves and cheer deck sleeves. You can go to the “Sleeves” tab in the deckbuilder to add them.

Pressing the “Cosmetics” button on the main menu will take you to a menu with two tabs. The “Playmat/Dice” tab will let you set the playmat, die, and sp marker images. The “Default Sleeves” tab will let you set which sleeves to use when your chosen deck doesn’t have any sleeves of its own.

You can find templates for all of these in the pinned posts in #delta-cosmetics on the discord.

While in-game, you can go to the settings panel on the sidebar and check “Hide Opponent Cosmetics” if you find them distasteful.


# Future Features

I am busy, both with ‘real’ work and just other personal projects I’d like to do. As such, updates have been slow and infrequent lately (though I place a strong emphasis on keeping things up-to-date). I have a lengthy list of features I’d like to implement without even getting into the massive undertakings like implementing custom cards or some form of automation.

If you have suggestions for how holoDelta could be improved to add to that list, please speak up in #delta-suggestion on the discord. If you encounter something you believe to be a bug, please speak up in #delta-bug-reports on the discord. If you do, please try to give as much relevant information as possible as to what was happening around the suspected glitch. Also, reports of things relating to the server connection will probably just be shrugged at, as that is known to be messed up and I am very uneducated about how to make the internet work well.

Also, holoDelta is open-source and I welcome contributions. The code probably needs to be cleaned up and commented for this to be very feasible, but if you reach out to me I will be happy to explain any mysterious portions. I should also implement some github issues for various features to make it easier for other to implement them, but again – busy.


# Adding Cards To holoDelta

Lately, I’ve been trying to not be the one updating the card database that delta uses. I am rather busy and would prefer to spend whatever time I can find for delta on updates instead.

I still will update it myself if no one takes it up (after the entire set including alt arts has been posted to the official website), but I would greatly appreciate someone else taking it up.

I have a janky program that I use to (relatively) quickly add cards to the database, and I made an unlisted video explaining how to use it at https://youtu.be/RsnDqGhRm1E. The relevant links are also in that video’s description.

Keep in mind that it’s okay to make some mistakes, as fixing a scattering of errors is much easier and less time-consuming for me than adding every card myself. You do need to include the Japanese text though. That part is non-negotiable.

Yes, there should be a better method for this. I’ve been meaning to work on one, but again – busy.