# CONTRIBUTING.md
If you are interested in contributing but are confused by the code, please message me on Discord. I can be found on the [Hololive OCG Fan Server](https://discord.com/invite/dDCpFMMENM).

In terms of what to contribute, the only thing that is fully off limits is automation. That is something I want to do myself at some point. To that end, the standard is "not implementing anything that depends on the specific text of a card."

---

There are some simpler things you can do that might be good entry-level tasks to just get used to Godot and holoDelta in particular:
- [ ] **Add the ability to rematch after a game ends** - once again, implementation is the issue here. Does it use the same decks? If not, how is that dealt with? Is it the same banlist? Depending on how in depth you wanna get, this could baloon into a larger task.
- [ ] **Add the ability to reorder cards in hand.** You literally just need to reorder the hand array and then call update_hand(). Implementation is once again the issue.
- [ ] **More scalable GUIs** - when I first made the sim, I wasn't aware of HBox and VBox containers, so many GUI elements are manually placed. This causes problems with different languages changing the size of text. Busy work, but it's gotta be done.
- [ ] Speaking of other languages messing up the GUI, I've got a bit of code in "Multiplayer.gd" and "deck_creation.gd" called "fix_font_size()" (that relies on "fix_font_tool.gd") that tries to change the font size of various text elements to fit the size allotted. It is a mess that barely works and I don't understand it. Everytime I try to make it more understandable, it gets far worse. Please help.
- [ ] If you know things about servers and Azure App Service in particular - please tell me what you know to make it go smoother
- [ ] Generally any tiny bug you notice is probably not a huge fix

What follows is a list of other things I would like to implement. If you are a collaborator who has become familiar with the system, feel free to look here for inspiration. You can also do whatever you feel like is important (except automation). For non-contributors, you can treat it as a list of things I am aware of and would also like to get to. Something appearing here is not a promise that I will do it; there's too many I literally can't.

- [ ] Playfab integration to have accounts consistent across devices. Would also allow some kind of moderation system.
- [ ] The ability to modify the holoDelta card info through the website so collaborators can do that instead of just me. Would probably require Playfab integration to ensure only trusted people can make changes.
- [ ] **Better solo play.** Shouldn't be awful to make a custom game where you have no opponent and can just test combo lines or one where you switch between playing both sides when you hit "end turn"
- [ ] **Replays.** Moving to being server authoritative already made the game action-based, we would just need to save these actions and play them back in some custom game.
- [ ] **Import decks from Bushiroad decklog.** I have no idea how, but I feel like it's not awful. Probably steal a couple pages from Qrimpuff's deck converter. The deckbuilder is getting crowded.
- [ ] **Better deck selection.** A search function, filter based on what cards are in it, stuff like that
- [ ] **Better chat.** Something like having each new message pop up briefly on screen? Text to speech? Just something to make it easier to use while still looking at the info panel.
- [ ] Obviously getting cosmetics back in. The issue is the file would have to be stored somewhere and I'm not sure how best to do that. Maybe something like azure blob storage?
- [ ] **Custom card support.** Moving on to cardData.json allows for the card info to be done pretty easily, the issue is once again that the images have to be stored somewhere. And this could easily blow up much larger than the cosmetics would.
  - [ ] the ability to make custom cards through holoDelta.
- [ ] **Multi-select cards in lists.** Mainly for that Chloe effect that puts all holomems in archive to deck. Lots of systems would need to be built up.