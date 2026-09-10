/datum/antagonist/sabbatist
	name = "Sabbatist"
	roundend_category = "sabbattites"
	antagpanel_category = FACTION_SABBAT
	pref_flag = ROLE_SABBAT
	antag_moodlet = /datum/mood_event/revolution
	antag_hud_name = "pack"
	ui_name = null
	hud_icon = 'modular_darkpack/modules/jobs/icons/sabbat.dmi'
	// CRIMSON EDIT ADD START - Sabbat Goals
	var/datum/team/sabbat/sabbat_team
	// CRIMSON EDIT ADD END - Sabbat Goals

/datum/antagonist/sabbatist/apply_innate_effects(mob/living/mob_override)
	. = ..()
	add_team_hud(owner.current, /datum/antagonist/sabbatist) // CRIMSON EDIT - Sabbat Identifier Fix - Original: add_team_hud(owner.current)

/datum/antagonist/sabbatist/on_removal()
	to_chat(owner.current, span_userdanger("You are no longer the part of Sabbat!"))
	return ..()

// CRIMSON EDIT ADD START - Sabbat Goals
/datum/antagonist/sabbatist/create_team(datum/team/sabbat/new_team)
	if(!new_team)
		GLOB.sabbat_team ||= new /datum/team/sabbat()
		sabbat_team = GLOB.sabbat_team
		return
	if(!istype(new_team))
		stack_trace("Wrong team type passed to [type] initialization.")
	sabbat_team = new_team

/datum/antagonist/sabbatist/get_team()
	return sabbat_team

/datum/antagonist/sabbatist/on_gain()
	. = ..()
	if(!sabbat_team?.chosen_path)
		return
	objectives |= sabbat_team.objectives
	if(owner.current)
		to_chat(owner.current, span_alertsyndie("The pack has chosen the Path of the [sabbat_team.chosen_path]."))
	owner.announce_objectives()
// CRIMSON EDIT ADD END - Sabbat Goals

/datum/antagonist/sabbatist/greet()
	to_chat(owner.current, span_alertsyndie("You are now part of the Sabbat."))
	//owner.announce_objectives()
