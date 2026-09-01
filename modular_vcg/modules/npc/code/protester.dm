/obj/item/picket_sign/endron
	name = "End Endron sign"
	desc = "It reads: End Endron"
	label = "End Endron"

/obj/item/picket_sign/gaia
	name = "Gaia Weeps sign"
	desc = "It reads: Gaia Weeps"
	label = "Gaia Weeps"

/datum/socialrole/protester
	max_age = 65
	male_names = null
	female_names = null
	surnames = null
	shoes = list(
		/obj/item/clothing/shoes/vampire/sneakers,
		/obj/item/clothing/shoes/vampire
	)
	uniforms = list(
		/obj/item/clothing/under/vampire/emo,
		/obj/item/clothing/under/vampire/sport,
		/obj/item/clothing/under/vampire/gothic
	)
	inhand_items = list(
		/obj/item/picket_sign/endron,
		/obj/item/picket_sign/gaia
	)
	pockets = list(
		/obj/item/vamp/keys/npc
	)
	random_phrases = list(
		"Endron bleeds the planet dry for their own profit!",
		"They did it on purpose!",
		"They are killing our planet!",
		"One cut tree is too many!",
		"Gaia has suffered enough!",
		"You know the oil spill in the Gulf? That was them, man!",
		"You know the Great Reef? It's GONE, man!",
		"Hey hey, ho ho, Endron has got to go!",
		"What do we want? Clean water! When do we want it? Now!",
		"You cannot drink money!",
		"There is only one Earth!",
		"Whose planet? Our planet!",
		"Shut it down! Shut the whole thing down!",
		"The rivers are not a sewer!",
		"Our children have to breathe this air!",
		"Wake up, man! Just look around you!"
	)
	neutral_phrases = list(
		"Sign the petition.",
		"You should be out here with us.",
		"Ask me what Endron did.",
		"Not now, I am working."
	)
	help_phrases = list(
		"They sent someone! I knew they would!",
		"This is what they do to people like us!",
		"Someone film this!",
		"Get off me! Get off!",
		"Endron sent you! I know they did!",
		"They do not want us talking!",
		"See what they are willing to do?",
		"Witnesses! I need witnesses!",
		"Get a camera over here!",
		"Let go of me! Let go!"
	)

/datum/socialrole/protester/male
	preferred_gender = MALE
	male_phrases = list(
		"Sign the petition.",
		"You should be out here with us.",
		"Ask me what Endron did.",
		"Not now, I am working."
	)

/datum/socialrole/protester/female
	preferred_gender = FEMALE
	female_phrases = list(
		"Sign the petition.",
		"You should be out here with us.",
		"Ask me what Endron did.",
		"Not now, I am working."
	)

/mob/living/carbon/human/npc/protester
	COOLDOWN_DECLARE(chant_cooldown)

/mob/living/carbon/human/npc/protester/Initialize(mapload)
	. = ..()

	var/datum/socialrole/assign_role = pick(/datum/socialrole/protester/male, /datum/socialrole/protester/female)
	AssignSocialRole(assign_role)

	var/obj/item/picket_sign/sign = locate() in held_items
	if(sign)
		register_sticky_item(sign)

/mob/living/carbon/human/npc/protester/handle_automated_movement()
	. = ..()

	if(stat >= HARD_CRIT || !COOLDOWN_FINISHED(src, chant_cooldown))
		return
	COOLDOWN_START(src, chant_cooldown, rand(20 SECONDS, 40 SECONDS))

	if(prob(50))
		realistic_say(pick(socialrole?.random_phrases))
		return

	var/obj/item/picket_sign/sign = locate() in held_items
	sign?.attack_self(src)
