#define SABBAT_PATH_SWORD "Sword"
#define SABBAT_PATH_FAITH "Faith"
#define SABBAT_PATH_WILL "Will"
#define SABBAT_PATH_DECISION_WINDOW (30 SECONDS)
#define SABBAT_PATH_TEXT_MAX_LENGTH 300
#define SABBAT_KINDRED_TO_CONVERT 3
#define SABBAT_HUMANS_TO_GHOUL 3
#define SABBAT_CHURCH_HOLD_TIME (15 MINUTES)
#define SABBAT_CHURCH_CHECK_INTERVAL (30 SECONDS)
#define SABBAT_CAMARILLA_CHECK_INTERVAL (30 SECONDS)

GLOBAL_DATUM(sabbat_team, /datum/team/sabbat)

GLOBAL_LIST_INIT(sabbat_target_priority, list(
	JOB_PRINCE,
	JOB_SENESCHAL,
	JOB_SHERIFF,
	JOB_HOUND,
	JOB_HARPY,
	JOB_PRIMOGEN_BRUJAH,
	JOB_PRIMOGEN_TOREADOR,
	JOB_PRIMOGEN_BANU_HAQIM,
	JOB_PRIMOGEN_LASOMBRA,
	JOB_PRIMOGEN_MALKAVIAN,
	JOB_PRIMOGEN_NOSFERATU,
	JOB_PRIMOGEN_VENTRUE,
	JOB_PENTEX_LEAD,
	JOB_PENTEX_EXEC,
))

GLOBAL_LIST_INIT(sabbat_officer_titles, list(
	JOB_PRINCE,
	JOB_SENESCHAL,
	JOB_SHERIFF,
	JOB_HOUND,
	JOB_HARPY,
	JOB_PRIMOGEN_BRUJAH,
	JOB_PRIMOGEN_TOREADOR,
	JOB_PRIMOGEN_BANU_HAQIM,
	JOB_PRIMOGEN_LASOMBRA,
	JOB_PRIMOGEN_MALKAVIAN,
	JOB_PRIMOGEN_NOSFERATU,
	JOB_PRIMOGEN_VENTRUE,
))

GLOBAL_LIST_INIT(sabbat_elder_titles, list(
	JOB_PRINCE,
	JOB_SENESCHAL,
	JOB_SHERIFF,
	JOB_PRIMOGEN_BRUJAH,
	JOB_PRIMOGEN_TOREADOR,
	JOB_PRIMOGEN_BANU_HAQIM,
	JOB_PRIMOGEN_LASOMBRA,
	JOB_PRIMOGEN_MALKAVIAN,
	JOB_PRIMOGEN_NOSFERATU,
	JOB_PRIMOGEN_VENTRUE,
))

/datum/team/sabbat
	name = "\improper Sabbat"
	member_name = "sabbattite"
	var/chosen_path
	var/camarilla_kills_required = 0
	var/kindred_converted = 0
	var/humans_ghouled = 0
	var/elder_diablerized = FALSE
	var/officer_converted = FALSE
	var/church_held = FALSE
	var/datum/mind/assassination_target
	var/church_hold_progress = 0
	var/list/camarilla_seen = list()
	var/decision_in_progress = FALSE

/datum/team/sabbat/New(starting_members)
	. = ..()
	camarilla_kills_required = rand(3, 6)
	track_camarilla()

/datum/team/sabbat/proc/track_camarilla()
	addtimer(CALLBACK(src, PROC_REF(track_camarilla)), SABBAT_CAMARILLA_CHECK_INTERVAL)
	for(var/datum/mind/checking as anything in SSticker.minds)
		if(checking.assigned_role?.faction != FACTION_CAMARILLA)
			continue
		if(considered_alive(checking))
			camarilla_seen |= checking

/datum/team/sabbat/proc/count_camarilla_dead()
	var/tally = 0
	for(var/datum/mind/checking as anything in camarilla_seen)
		if(!considered_alive(checking))
			tally++
	return tally

/datum/team/sabbat/proc/pick_assassination_target()
	for(var/title in GLOB.sabbat_target_priority)
		for(var/datum/mind/checking as anything in SSticker.minds)
			if(checking.assigned_role?.title != title || !considered_alive(checking))
				continue
			assassination_target = checking
			return checking
	return null

/datum/team/sabbat/proc/get_living_ductus()
	for(var/datum/mind/member as anything in members)
		if(is_sabbat_ductus(member.assigned_role) && considered_alive(member))
			return member
	return null

/datum/team/sabbat/proc/can_call_path_rite(mob/living/user)
	if(chosen_path || decision_in_progress || !user?.mind)
		return FALSE
	return is_sabbat_priest(user.mind.assigned_role)

/datum/team/sabbat/proc/start_path_rite(mob/living/rite_caller)
	if(chosen_path || decision_in_progress)
		return
	var/datum/mind/ductus = get_living_ductus()
	if(!ductus)
		to_chat(rite_caller, span_warning("Without a Ductus, no Path can be set."))
		return
	decision_in_progress = TRUE
	for(var/datum/mind/member as anything in members)
		if(member.current)
			to_chat(member.current, span_cult("[rite_caller] calls the Auctoritas of the Path. The pack's Ductus will decide the course of the night."))
	INVOKE_ASYNC(src, PROC_REF(poll_ductus), ductus)

/datum/team/sabbat/proc/poll_ductus(datum/mind/ductus)
	var/choice
	var/written_objective
	if(ductus.current)
		choice = tgui_alert(ductus.current, "The pack must choose its Path for the night.", "Sabbat", list(SABBAT_PATH_SWORD, SABBAT_PATH_FAITH, SABBAT_PATH_WILL), timeout = SABBAT_PATH_DECISION_WINDOW)
	if(choice == SABBAT_PATH_WILL && ductus.current)
		written_objective = tgui_input_text(ductus.current, message = "Declare the pack's mission for the night", title = "Path of the Will", max_length = SABBAT_PATH_TEXT_MAX_LENGTH, timeout = SABBAT_PATH_DECISION_WINDOW)
		if(!written_objective)
			choice = null
	decision_in_progress = FALSE
	if(!choice)
		return
	if(written_objective)
		log_game("[key_name(ductus.current)] set the Sabbat pack objective: [written_objective]")
		message_admins("[ADMIN_LOOKUPFLW(ductus.current)] set the Sabbat pack objective: [span_syndradio("[written_objective]")]")
	set_path(choice, written_objective)

/datum/team/sabbat/proc/set_path(path, written_objective)
	if(chosen_path)
		return
	chosen_path = path
	switch(path)
		if(SABBAT_PATH_SWORD)
			if(pick_assassination_target())
				add_objective(new /datum/objective/sabbat/assassinate_target)
			add_objective(new /datum/objective/sabbat/kill_camarilla)
			add_objective(new /datum/objective/sabbat/diablerize_elder)
		if(SABBAT_PATH_FAITH)
			add_objective(new /datum/objective/sabbat/convert_kindred)
			add_objective(new /datum/objective/sabbat/convert_officer)
			add_objective(new /datum/objective/sabbat/ghoul_humans)
			add_objective(new /datum/objective/sabbat/hold_church)
			addtimer(CALLBACK(src, PROC_REF(check_church_hold)), SABBAT_CHURCH_CHECK_INTERVAL)
		if(SABBAT_PATH_WILL)
			var/datum/objective/custom/written = new()
			add_objective(written)
			written.explanation_text = written_objective
			written.completed = TRUE
	share_objectives()
	announce_path()

/datum/team/sabbat/proc/share_objectives()
	for(var/datum/mind/member as anything in members)
		var/datum/antagonist/sabbatist/record = member.has_antag_datum(/datum/antagonist/sabbatist)
		if(!record)
			continue
		record.objectives |= objectives

/datum/team/sabbat/proc/announce_path()
	for(var/datum/mind/member as anything in members)
		if(!member.current)
			continue
		to_chat(member.current, span_alertsyndie("The pack has chosen the Path of the [chosen_path]."))
		member.announce_objectives()

/datum/objective/sabbat

/datum/objective/sabbat/diablerize_elder
	name = "sabbat diablerize elder"
	explanation_text = "Diablerize an elder of the Camarilla."

/datum/objective/sabbat/diablerize_elder/check_completion()
	var/datum/team/sabbat/pack = team
	return pack.elder_diablerized

/datum/objective/sabbat/kill_camarilla
	name = "sabbat kill camarilla"

/datum/objective/sabbat/kill_camarilla/update_explanation_text()
	var/datum/team/sabbat/pack = team
	explanation_text = "Leave [pack.camarilla_kills_required] of the Camarilla dead before dawn."

/datum/objective/sabbat/kill_camarilla/check_completion()
	var/datum/team/sabbat/pack = team
	return pack.count_camarilla_dead() >= pack.camarilla_kills_required

/datum/objective/sabbat/assassinate_target
	name = "sabbat assassinate"

/datum/objective/sabbat/assassinate_target/update_explanation_text()
	var/datum/team/sabbat/pack = team
	var/datum/mind/target = pack.assassination_target
	explanation_text = "Assassinate [target.name], the [target.assigned_role?.title]."

/datum/objective/sabbat/assassinate_target/check_completion()
	var/datum/team/sabbat/pack = team
	return !considered_alive(pack.assassination_target)

/datum/objective/sabbat/convert_kindred
	name = "sabbat convert kindred"

/datum/objective/sabbat/convert_kindred/update_explanation_text()
	explanation_text = "Bring [SABBAT_KINDRED_TO_CONVERT] Kindred into the pack through the Vaulderie."

/datum/objective/sabbat/convert_kindred/check_completion()
	var/datum/team/sabbat/pack = team
	return pack.kindred_converted >= SABBAT_KINDRED_TO_CONVERT

/datum/objective/sabbat/convert_officer
	name = "sabbat convert officer"
	explanation_text = "Break an officer of the Camarilla and bring them to the pack."

/datum/objective/sabbat/convert_officer/check_completion()
	var/datum/team/sabbat/pack = team
	return pack.officer_converted

/datum/objective/sabbat/ghoul_humans
	name = "sabbat ghoul humans"

/datum/objective/sabbat/ghoul_humans/update_explanation_text()
	explanation_text = "Bind [SABBAT_HUMANS_TO_GHOUL] mortals to the pack as ghouls."

/datum/objective/sabbat/ghoul_humans/check_completion()
	var/datum/team/sabbat/pack = team
	return pack.humans_ghouled >= SABBAT_HUMANS_TO_GHOUL



/datum/team/sabbat/proc/register_conversion(mob/living/carbon/human/convert)
	if(!convert?.mind)
		return
	if(get_kindred_splat(convert))
		kindred_converted++
	if(convert.mind.assigned_role?.title in GLOB.sabbat_officer_titles)
		officer_converted = TRUE

/datum/team/sabbat/proc/register_ghouling(mob/living/ghouled, mob/living/domitor)
	if(!ishuman(ghouled) || get_vampire_splat(ghouled))
		return
	if(!domitor?.mind || !is_sabbatist(domitor.mind.assigned_role))
		return
	humans_ghouled++

/datum/team/sabbat/proc/register_diablerie(mob/living/carbon/human/diablerist, mob/living/victim)
	if(!diablerist?.mind || !is_sabbatist(diablerist.mind.assigned_role))
		return
	if(!(victim?.mind?.assigned_role?.title in GLOB.sabbat_elder_titles))
		return
	elder_diablerized = TRUE

/datum/team/sabbat/proc/is_pack_ghoul(mob/living/checking)
	var/datum/splat/vampire/ghoul/ghoul_splat = get_ghoul_splat(checking)
	if(!ghoul_splat?.domitor?.mind)
		return FALSE
	return is_sabbatist(ghoul_splat.domitor.mind.assigned_role)

/datum/team/sabbat/proc/check_church_hold()
	if(church_held)
		return
	addtimer(CALLBACK(src, PROC_REF(check_church_hold)), SABBAT_CHURCH_CHECK_INTERVAL)
	var/area/vtm/chapel = GLOB.areas_by_type[/area/vtm/interior/church]
	if(!chapel)
		return
	var/sabbat_present = FALSE
	for(var/mob/living/carbon/human/checking as anything in GLOB.human_list)
		if(checking.stat == DEAD || get_area(checking) != chapel)
			continue
		if(checking.mind && is_sabbatist(checking.mind.assigned_role))
			sabbat_present = TRUE
			continue
		if(is_pack_ghoul(checking))
			continue
		return
	if(!sabbat_present)
		return
	church_hold_progress += SABBAT_CHURCH_CHECK_INTERVAL
	if(church_hold_progress < SABBAT_CHURCH_HOLD_TIME)
		return
	church_held = TRUE
	chapel.zone_type = ZONE_NO_MASQUERADE
	for(var/datum/mind/member as anything in members)
		if(member.current)
			to_chat(member.current, span_cult("The church is now a temple. Rejoice."))

/datum/objective/sabbat/hold_church
	name = "sabbat hold church"
	explanation_text = "Convert the church into a temple and hold it."

/datum/objective/sabbat/hold_church/check_completion()
	var/datum/team/sabbat/pack = team
	return pack.church_held

#undef SABBAT_PATH_SWORD
#undef SABBAT_PATH_FAITH
#undef SABBAT_PATH_WILL
#undef SABBAT_PATH_DECISION_WINDOW
#undef SABBAT_PATH_TEXT_MAX_LENGTH
#undef SABBAT_KINDRED_TO_CONVERT
#undef SABBAT_HUMANS_TO_GHOUL
#undef SABBAT_CHURCH_HOLD_TIME
#undef SABBAT_CHURCH_CHECK_INTERVAL
#undef SABBAT_CAMARILLA_CHECK_INTERVAL
