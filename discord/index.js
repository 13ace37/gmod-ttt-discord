var config = require("./config");

const app = require("express")();

var { Client, Intents } = require("discord.js"),
Client = new Client({ intents: [Intents.FLAGS.GUILDS, Intents.FLAGS.GUILD_MEMBERS, Intents.FLAGS.GUILD_BANS, Intents.FLAGS.GUILD_EMOJIS_AND_STICKERS, Intents.FLAGS.GUILD_INTEGRATIONS, Intents.FLAGS.GUILD_WEBHOOKS, Intents.FLAGS.GUILD_INVITES, Intents.FLAGS.GUILD_VOICE_STATES, Intents.FLAGS.GUILD_PRESENCES, Intents.FLAGS.GUILD_MESSAGES, Intents.FLAGS.GUILD_MESSAGE_REACTIONS, Intents.FLAGS.GUILD_MESSAGE_TYPING, Intents.FLAGS.DIRECT_MESSAGES, Intents.FLAGS.DIRECT_MESSAGE_REACTIONS, Intents.FLAGS.DIRECT_MESSAGE_TYPING, Intents.FLAGS.GUILD_SCHEDULED_EVENTS] });
Client.login(config.token);


app.listen(config.port, () => console.log("web running"));
Client.once("ready", () => console.log("discord running"));


var functions = {

	move: async (req, res, next) => {
		let guild = await Client.guilds.fetch(config.guild);
		let member = await guild.members.fetch(req.headers.params.id)
		if (!member.voice?.channelId) return res.send({success: false, err: "member not in any channel"});
		if (member.voice?.channelId == config.voiceChannel) return res.send({success: false, err: "member already in channel"});
		console.log("client joined server. moving");
		member.voice.setChannel(config.voiceChannel);
		return res.send({success: true});
	},
	
	
	mute: async (req, res, next) => {
		let guild = await Client.guilds.fetch(config.guild);
		let member = await guild.members.fetch(req.headers.params.id)
		if (member.voice?.channelId != config.voiceChannel) return res.send({success: false, err: "member not in channel"});
		member.voice.setMute(req.headers.params.mute);
		return res.send({success: true});
	},
	
	
	connect: async (req, res, next) => {
		let guild = await Client.guilds.fetch(config.guild);
		let allMembers = await guild.members.list({limit: 100});
		req.headers.params.tag = req.headers.params.tag.split(" ").map(x => String.fromCharCode(x)).join("");
		let foundMembers = allMembers.filter(x => x.user.tag.toLowerCase().includes(req.headers.params.tag.toLowerCase()));
		let data = foundMembers.size == 1 ? { tag: foundMembers.at(0).user.tag, id: foundMembers.at(0).id } : { answer: foundMembers.size > 1 ? 1 : 0};
		res.send(data);
	},


}

app.get("/", (req, res, next) => {
	console.log(req.headers.req);
	try {
		req.headers.params = JSON.parse(req.headers.params); 
		functions[req.headers.req](req, res, next);
	} catch {}
});

