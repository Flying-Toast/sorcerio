///generic spell stuff
module wiziz.gameServer.spell;

import std.json : JSONValue;

import wiziz : millis;
import wiziz.gameServer.server;
import wiziz.gameServer.player;
import wiziz.gameServer.config;

///
enum SpellName {
	fire,
	slow,
	freeze,
	blind,
	heal,
	bomb,
	invisible,
	teleport,
	speed,
	shock,
	expansion,
	nuke,
	confuse,
	repel,
	snipe
}

/**
	Determines at what level spells get unlocked.

	The array key is the level that they get unlocked at.
	The spells at `[1]` are the default spells that players start with.
*/
private enum SpellName[][ushort] spellUnlocks = [
	//These ones are the default starting spells:
	1: [SpellName.fire],

	2: [SpellName.heal],
	3: [SpellName.bomb, SpellName.slow],
	4: [SpellName.blind, SpellName.speed],
	5: [SpellName.expansion, SpellName.freeze],
	6: [SpellName.teleport, SpellName.shock],
	7: [SpellName.invisible, SpellName.nuke],
	8: [SpellName.confuse, SpellName.repel],
	9: [SpellName.snipe]
];

version (unittest) {
	SpellName[] allUnlockableSpells() {///a single array of all SpellNames that are in spellUnlocks
		import std.algorithm.iteration;

		SpellName[] unlockableSpells;
		spellUnlocks.values.each!(value => value.each!(item => unlockableSpells ~= item));

		return unlockableSpells;
	}
}

/**
	Which spells are unlocked at `level`.

	Params:
		level = The level to get the unlocked spells for. The spells returned when `level` == 1 are the default spells that all players start with.
	Returns:
		The spells that a player unlocks when they reach `level`.
*/
SpellName[] unlockedSpells(ushort level) {
	if (level in spellUnlocks) {
		return spellUnlocks[level];
	}
	return [];
}

///generates a JSON array of all spell types, used for /public/meta.json
JSONValue generateSpellTypesJSON() {
	import std.traits;
	import std.conv;

	string[] types;
	foreach (member; [EnumMembers!SpellName]) {
		types ~= member.to!string;
	}

	return JSONValue(types);
}

///A spell in a player's inventory
final class InventorySpell {
	immutable SpellName name;
	private immutable uint coolDownTime;
	private long timeOfLastCast;
	private Player owner;///the player whose inventory contains this

	static JSONValue JSONofInventory(InventorySpell[] inventory) {
		JSONValue[] inventorySpellsJSON;

		foreach (spell; inventory) {
			if (spell is null) {
				continue;
			}

			inventorySpellsJSON ~= spell.JSONof();
		}

		return JSONValue(inventorySpellsJSON);
	}

	JSONValue JSONof() {
		import std.conv;

		JSONValue json = JSONValue();

		json["spellName"] = name.to!string;
		json["coolDownTime"] = coolDownTime;
		json["cooling"] = isCooling;

		return json;
	}

	bool isCooling() {
		if (millis() - timeOfLastCast >= coolDownTime) {
			return false;
		}
		return true;
	}

	///trys to cast the spell, returns whether or not it was actually casted
	bool castSpell(Server game) {
		if (isCooling) {
			return false;
		}

		game.addSpell(SpellFactory.createSpell(name, owner));

		timeOfLastCast = millis();
		return true;
	}

	this(SpellName name, Player owner) {
		this.name = name;
		this.coolDownTime = SpellFactory.getCoolDownTime(name);
		this.timeOfLastCast = 0;
		this.owner = owner;
	}
}

///Manages the creating of spells
final class SpellFactory {
	///an entry in the SpellFactory's registry
	private static class RegistryEntry {
		Spell spell;
		uint coolDownTime;///the coolDownTime of the inventory spell

		this(Spell spell, uint coolDownTime) {
			this.spell = spell;
			this.coolDownTime = coolDownTime;
		}
	}

	private static RegistryEntry[SpellName] registry;

	static void registerSpell(SpellName name, uint coolDownTime, Spell spell) {
		import std.conv;
		assert(name !in registry, text("Spell '", name, "' is already registered."));
		registry[name] = new RegistryEntry(spell, coolDownTime);
	}

	static Spell createSpell(SpellName name, Player caster) {
		return registry[name].spell.create(caster);
	}

	static uint getCoolDownTime(SpellName name) {
		return registry[name].coolDownTime;
	}

	static string[string] getHumanReadableEffects() {
		import std.conv;

		string[string] effects;
		foreach (name, entry; registry) {
			effects[name.to!string] = entry.spell.humanReadableEffect;
		}
		return effects;
	}
}


///Registers a spell with the SpellFactory
mixin template registerSpell(SpellName name, uint coolDownTime) {
	static this() {
		SpellFactory.registerSpell(name, coolDownTime, new typeof(this));
	}

	private this() {}

	this(Player caster) {
		this.caster = caster;
		cast(SpellName) this.name = name;
		initialize();
	}

	override Spell create(Player caster) {
		return new typeof(this)(caster);
	}
}


///A spell entity
abstract class Spell {
	const SpellName name;

	bool removalFlag = false;///flags the spell to be removed from Server.spells on the next tick. ALWAYS use removalFlag instead of directly removing the spell from the Server.spells array.

	/**
	JSON that represents this Spell.

	All spell JSONs $(B need) to have a string property called "renderFunction".
	The "renderFunction" property is the name of a function in the clientside code, and the rest of the spell JSON will be passed to that function to render it.

	For example, for projectile spells, there might be a single function called "renderProjectile" that can render all projectile spells.
	Then, any spell that declares its renderFunction as "renderProjectile", and thus gets passed to the renderProjectile() function, needs to also implement various other properties (in this case, `location`, `radius`, etc) that are specific to that type of spell.
	Alternatively, a spell can specify "renderFunction":"nothing", and then the spell will not be sent to clients.
	*/
	abstract JSONValue JSONof();

	protected Player caster;

	abstract Spell create(Player caster);

	///called once, right after object creation
	abstract void initialize();

	abstract void tick(Server gameState);

	///returns a string describing the effects of the spell
	abstract string humanReadableEffect();
}

unittest {///make sure that all spells are implemented
	import std.traits;
	import core.exception;
	import std.stdio;
	import std.conv;

	bool error = false;
	foreach (name; [EnumMembers!SpellName]) {
		//make sure that all spells are registered:
		try {
			SpellFactory.getCoolDownTime(name);
		} catch (RangeError e) {
			writeln("'", name.to!string, "' spell is not registered with SpellFactory.");
			error = true;
		}

		//make sure that all spells have images for their inventory slot:
		bool fileExists(string path) {
			import std.file;
			if (path.exists && path.isFile) {
				return true;
			}
			return false;
		}

		string inventoryItemPath = "public/media/images/" ~ name.to!string ~ "Spell.png";
		if (!fileExists(inventoryItemPath)) {
			writeln("'", name.to!string, "' spell does not have an inventory image at ", inventoryItemPath);
			error = true;
		}

		//make sure that all spells have sounds:
		string baseSoundPath = "public/media/sounds/" ~ name.to!string ~ "Spell.";
		if (!fileExists(baseSoundPath~"ogg")) {
			writeln("'", name.to!string, "' spell does not have a sound at ", baseSoundPath~"ogg");
			error = true;
		}

		if (!fileExists(baseSoundPath~"mp3")) {
			writeln("'", name.to!string, "' spell does not have a sound at ", baseSoundPath~"mp3");
			error = true;
		}

		//make sure all spells are unlockable:
		import std.algorithm.searching : canFind;
		if (!allUnlockableSpells.canFind(name)) {
			writeln("'", name.to!string, "' spell is not unlockable (not in `spellUnlocks`)");
			error = true;
		}
	}

	assert(!error, "Not all spells defined in SpellName are fully implemented (see above messages).");
}
