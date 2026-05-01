extends RefCounted
class_name NpcDialogues


static func get_timeline_text(key: String) -> String:
	match key.to_lower():
		"dominic":
			return _dominic_timeline()
		"victoria":
			return _victoria_timeline()
		"julian":
			return _julian_timeline()
		"luna":
			return _luna_timeline()
		"marcus":
			return _marcus_timeline()
		_:
			return ""


static func get_shadow_timeline_text(key: String) -> String:
	match key.to_lower():
		"dominic":
			return _dominic_shadow_timeline()
		"victoria":
			return _generic_shadow_timeline("Victoria")
		"julian":
			return _generic_shadow_timeline("Julian")
		"luna":
			return _generic_shadow_timeline("Luna")
		"marcus":
			return _generic_shadow_timeline("Marcus")
		_:
			return ""


static func _generic_shadow_timeline(speaker_name: String) -> String:
	return ("""
%s: ...
""" % speaker_name)


static func _dominic_shadow_timeline() -> String:
	return """
Ethan: You've been such a great host, but I noticed the victim's glass was specifically served without a guest sticker. Why was that one special?
Dominic: She was the last person to arrive and we've already run out of those stickers.
Ethan: The victim seemed to trust you more than anyone here. Is that why they didn't think twice when you handed them that last drink?
Dominic: Because everyone gets a welcoming drink. I'm not trying to differentiate her from the others.
"""


static func _dominic_timeline() -> String:
	return """
Ethan: Let's start with the basics - what's your name?
Dominic: I'm Dominic Hale. Dominic, for short.
Ethan: And what exactly is your role or job here?
Dominic: I'm the one who hosted this party. It's a celebration for my new business.
Ethan: Where were you hanging out when everything went wrong?
Dominic: I was in the garden with Victoria.
Ethan: What were you up to between 9:00 and 11:00? Give me the highlights.
Dominic: At 9 PM, I welcomed every guest at the front door. Then at 10 PM, I was at the party with everyone else, dancing. At 11, I was in the garden with Victoria. Then it's over.
Ethan: Did you happen to see the victim with anyone else earlier today? Any weird vibes?
Dominic: I did. She was with Luna. No, I think she looked as usual.
Ethan: Did you notice the victim sharing a drink or a snack with anyone specifically?
Dominic: I gave each of my guests a welcoming drink when they first arrived. Afterwards, I didn't really pay attention to her.
Ethan: Who here had a grudge against the victim? Or maybe who was a bit too friendly with them?
Dominic: I can't judge someone's relationship, but everyone knows about Luna and Valerie's rivalry.
Ethan: Who besides the host would have even had a chance to slip into the kitchen or bar unnoticed?
Dominic: Anyone could have walked in, so they could have drinks and food however they wanted.
Ethan: If you wanted to poison someone at a party like this, how would you make sure only the victim drank the tainted glass?
Dominic: Nothing. It's my party, and it's unfortunate how things could go wrong like this.
"""


static func _victoria_timeline() -> String:
	return """
Ethan: Let's start with the basics - what's your name?
Victoria: I'm Victoria Hayes.
Ethan: And what exactly is your role or job here?
Victoria: I would say a public figure.
Ethan: Where were you hanging out when everything went wrong?
Victoria: I was in the garden with Dominic, talking about business and stuff.
Ethan: What were you up to between 9:00 and 11:00? Give me the highlights.
Victoria: At 9 PM, I arrived at the party. At 10 PM, I was in the kitchen and eating at the studio. Then at 11 PM, I was with Dominic in the garden.
Ethan: Did you happen to see the victim with anyone else earlier today? Any weird vibes?
Victoria: She was with Luna - weird, knowing they're rivals. Then Julian, just the two of them in the kitchen.
Ethan: Did you notice the victim sharing a drink or a snack with anyone specifically?
Victoria: I left the kitchen early, but I strongly suspect Julian gave her pills.
Ethan: Who here had a grudge against the victim? Or maybe who was a bit too friendly with them?
Victoria: Everyone knows about Luna and Valerie. Old rivals since they were babies, maybe.
Ethan: Who besides the host would have even had a chance to slip into the kitchen or bar unnoticed?
Victoria: Everyone could, though it's a bit far from the party room.
Ethan: If you wanted to poison someone at a party like this, how would you make sure only the victim drank the tainted glass?
Victoria: I would approach them slowly, then go for a talk. Though I couldn't imagine doing so.
"""


static func _julian_timeline() -> String:
	return """
Ethan: Let's start with the basics - what's your name?
Julian: Julian Park.
Ethan: And what exactly is your role or job here?
Julian: I'm a chemist specialist.
Ethan: Where were you hanging out when everything went wrong?
Julian: I was in the living room.
Ethan: What were you up to between 9:00 and 11:00? Give me the highlights.
Julian: I arrived at 8:45 PM and talked with some old friends. At 10 PM, Valerie approached me and said she was sick. I gave her medicine and left. At 11 PM, I was in the living room with everyone else.
Ethan: Did you happen to see the victim with anyone else earlier today? Any weird vibes?
Julian: Luna. Then she looked very sick, pale, and said she was vomiting.
Ethan: Did you notice the victim sharing a drink or a snack with anyone specifically?
Julian: I don't know.
Ethan: Who here had a grudge against the victim? Or maybe who was a bit too friendly with them?
Julian: I think everyone has their own grudge toward her.
Ethan: Who besides the host would have even had a chance to slip into the kitchen or bar unnoticed?
Julian: The chef. But everyone could, honestly.
Ethan: If you wanted to poison someone at a party like this, how would you make sure only the victim drank the tainted glass?
Julian: Usually people would go with an overdose.
"""


static func _luna_timeline() -> String:
	return """
Ethan: Let's start with the basics - what's your name?
Luna: I'm Luna, Luna Hart.
Ethan: And what exactly is your role or job here?
Luna: I think everyone knows me well. I'm an influencer - of course I would never risk my persona.
Ethan: Where were you hanging out when everything went wrong?
Luna: I was in the bathroom, then I heard something drop and saw Valerie already dying next door.
Ethan: What were you up to between 9:00 and 11:00? Give me the highlights.
Luna: I arrived a little late because I had work to do. At 10, I was talking with Valerie about our upcoming collab. My period cramps killed me at 11 PM, then I found the body.
Ethan: Did you happen to see the victim with anyone else earlier today? Any weird vibes?
Luna: She was different, odd. Not annoying as usual - she looked sick and not in the right mind.
Ethan: Did you notice the victim sharing a drink or a snack with anyone specifically?
Luna: We drank tequila together from Marcus, the chef.
Ethan: Who here had a grudge against the victim? Or maybe who was a bit too friendly with them?
Luna: Everyone does. But everyone also does their best to hide it. I don't know - maybe Julian, maybe Marcus.
Ethan: Who besides the host would have even had a chance to slip into the kitchen or bar unnoticed?
Luna: The chef.
Ethan: If you wanted to poison someone at a party like this, how would you make sure only the victim drank the tainted glass?
Luna: I would play safe. But no, this one definitely is not safe. It's not me.
"""


static func _marcus_timeline() -> String:
	return """
Ethan: Let's start with the basics - what's your name?
Marcus: Marcus.
Ethan: And what exactly is your role or job here?
Marcus: The chef.
Ethan: Where were you hanging out when everything went wrong?
Marcus: I was in the kitchen.
Ethan: What were you up to between 9:00 and 11:00? Give me the highlights.
Marcus: I've been at the party since 5 PM preparing everything - welcoming drinks, dessert, appetizer, never mind. I was in the kitchen the whole time.
Ethan: Did you happen to see the victim with anyone else earlier today? Any weird vibes?
Marcus: I don't remember their names. Luna, and the chemist guy, I suppose.
Ethan: Did you notice the victim sharing a drink or a snack with anyone specifically?
Marcus: She requested tequila with Luna. Then they ate appetizers at the table. She looked sick, then the guy gave her medicine.
Ethan: Who here had a grudge against the victim? Or maybe who was a bit too friendly with them?
Marcus: I don't know. I'm not that close with her.
Ethan: Who besides the host would have even had a chance to slip into the kitchen or bar unnoticed?
Marcus: Me, but some guests offered help or just slipped in because there's no key to lock the door.
Ethan: If you wanted to poison someone at a party like this, how would you make sure only the victim drank the tainted glass?
Marcus: I would make sure I'm not the chef for the party.
"""
