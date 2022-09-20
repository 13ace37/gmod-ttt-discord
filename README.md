# gmod-ttt-discord
Automatic Discord Mute for TTT

---

__I provide my plugins/code without an explanation for a reason! If you don't know how to use it, keep it that way! It's the worst thing: Trying to support people that have no clue about what they are doing!__
__This is nothing to deploy and just run without knowledge about what you are doing!__


This project was strongly inspired by the ["original" project](https://github.com/marceltransier/ttt_discord_bot) and its predecessor [JS](https://github.com/manix84/discord_gmod_bot)/[LUA](https://github.com/manix84/discord_gmod_addon). 
The JavaScript part was completely renewed and brought to a more current discord.js state. Also the web requests are now handled by express.js. The codebase was also modernized and minimized for efficiency. 

The Lua part was not touched much, rather just refactored and written 100% in vanilla lua.

Users joining the server are now automatically moved to the defined game channel. So it is possible to have this invisible on a public server, without a non-player disturbing the game.

Possible targets

- [ ] Multilingualism for text messages from the plugin
- [ ] Webrequests via endpoints instead of headers

