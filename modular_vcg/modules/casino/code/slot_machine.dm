#define SPIN_PRICE 5
#define WINNING_NOTHING 0
#define WINNING_SMALL 2
#define WINNING_BIG 3
#define WINNING_JACKPOT 4
#define PRIZE_SMALL 150
#define PRIZE_BIG 400
#define PRIZE_JACKPOT 5000

/obj/machinery/computer/slot_machine/darkpack
	desc = "A slot machine with mesmerizing lights and sounds. Pull its arm and watch it go!"
	circuit = null
	processing_flags = NONE
	money = 1500
	symbol_paths = list(
		/obj/item/stack/sheet/mineral/gold = 4,
		/obj/item/stack/sheet/mineral/diamond = 4,
		/obj/item/clothing/head/costume/crown/fancy = 10,
		/obj/item/food/grown/cherries = 4,
		/obj/item/food/grown/citrus/orange = 4,
		/obj/item/food/grown/banana = 4,
		/obj/item/food/watermelonslice = 4,
	)
	jackpot_path = /obj/item/clothing/head/costume/crown/fancy
	trap_path = null
	var/datum/looping_sound/jackpot/jackpot_loop
	var/list/winning_line = list()
	var/winning_length = 0
	var/static/list/paylines = list(
		list(2, 2, 2, 2, 2),
		list(1, 1, 1, 1, 1),
		list(3, 3, 3, 3, 3),
		list(1, 2, 3, 2, 1),
		list(3, 2, 1, 2, 3),
	)
	var/static/list/symbol_scales = list(
		/obj/item/stack/sheet/mineral/diamond = 4,
		/obj/item/food/grown/cherries = 2.2,
		/obj/item/food/grown/banana = 2,
	)
	var/static/list/symbol_offsets = list(
		/obj/item/stack/sheet/mineral/diamond = -1.5,
	)

/obj/machinery/computer/slot_machine/darkpack/Initialize(mapload)
	. = ..()
	plays = 0
	jackpots = 0
	jackpot_loop = new(src, FALSE)

/obj/machinery/computer/slot_machine/darkpack/make_machine_name()
	return name

/obj/machinery/computer/slot_machine/darkpack/item_interaction(mob/living/user, obj/item/inserted, list/modifiers)
	if(istype(inserted, /obj/item/vamp/keys))
		house_access(user, inserted)
		return ITEM_INTERACT_SUCCESS
	if(!istype(inserted, /obj/item/stack/dollar))
		return NONE
	if(!area_has_locked_door(get_area(src)))
		to_chat(user, span_notice("The machine appears to be off."))
		return ITEM_INTERACT_BLOCKING
	var/obj/item/stack/dollar/inserted_cash = inserted
	balloon_alert(user, "[inserted_cash.amount] [MONEY_NAME_AUTOPURAL(inserted_cash.amount)] inserted")
	balance += inserted_cash.amount
	qdel(inserted_cash)
	return ITEM_INTERACT_SUCCESS

/obj/machinery/computer/slot_machine/darkpack/multitool_act(mob/living/user, obj/item/tool)
	return NONE

/obj/machinery/computer/slot_machine/darkpack/has_funds_to_pay(payout)
	if(money >= PRIZE_BIG)
		return TRUE
	say("The machine is out of money.")
	playsound(src, 'sound/machines/buzz/buzz-two.ogg', 30, TRUE)
	return FALSE

/obj/machinery/computer/slot_machine/darkpack/ui_data(mob/user)
	. = ..()
	.["winning_line"] = winning_line
	.["winning_length"] = winning_length

/obj/machinery/computer/slot_machine/darkpack/ui_static_data(mob/user)
	. = ..()
	.["jackpot"] = PRIZE_JACKPOT
	.["prizes"] = list(SPIN_PRICE * 2, PRIZE_SMALL, PRIZE_BIG)

/obj/machinery/computer/slot_machine/darkpack/dispense(amount = 0, cointype = /obj/item/coin/silver, throwit = FALSE, mob/living/target)
	new /obj/item/stack/dollar(loc, amount)
	playsound(src, pick(list('sound/machines/coindrop.ogg', 'sound/machines/coindrop2.ogg')), 50, TRUE)
	return amount

/obj/machinery/computer/slot_machine/darkpack/build_symbol_data()
	. = ..()
	for(var/list/symbol in symbol_data)
		var/symbol_path = text2path(symbol["id"])
		symbol["scale"] = symbol_scales[symbol_path]
		symbol["offset"] = symbol_offsets[symbol_path]

/obj/machinery/computer/slot_machine/darkpack/randomize_reels()
	for(var/list/reel in reels)
		reel[1] = "[pick_weight(symbol_paths)]"
		reel[2] = "[pick_weight(symbol_paths)]"
		reel[3] = "[pick_weight(symbol_paths)]"

/obj/machinery/computer/slot_machine/darkpack/proc/find_best_line()
	winning_line = list()
	winning_length = 0
	for(var/list/payline in paylines)
		var/line_length = 1
		while(line_length < length(reels) && reels[line_length + 1][payline[line_length + 1]] == reels[1][payline[1]])
			line_length++
		if(line_length >= 3 && line_length > winning_length)
			winning_line = payline
			winning_length = line_length

/obj/machinery/computer/slot_machine/darkpack/give_prizes(usrname, mob/living/user)
	find_best_line()
	var/did_player_win = TRUE

	if(winning_length == 5 && reels[1][winning_line[1]] == "[jackpot_path]")
		winning = WINNING_JACKPOT
		var/prize = money + PRIZE_JACKPOT
		to_chat(user, span_notice("JACKPOT! You win [prize] [MONEY_NAME]!"))
		balloon_alert_to_viewers("JACKPOT!", ignored_mobs = list(user))
		jackpot_loop.start()
		addtimer(CALLBACK(jackpot_loop, TYPE_PROC_REF(/datum/looping_sound, stop)), 3 SECONDS)
		user.add_mood_event(SLOTS_MOOD_CATEGORY, /datum/mood_event/slots/win/jackpot)
		add_memory_in_range(user, 7, /datum/memory/won_jackpot, protagonist = user, deuteragonist = src)
		jackpots += 1
		money = 0
		dispense(prize)

	else if(winning_length == 5)
		winning = WINNING_BIG
		to_chat(user, span_notice("Big Winner! You win [PRIZE_BIG] [MONEY_NAME]!"))
		balloon_alert_to_viewers("Big Winner!", ignored_mobs = list(user))
		give_money(PRIZE_BIG)
		user.add_mood_event(SLOTS_MOOD_CATEGORY, /datum/mood_event/slots/win/big)

	else if(winning_length == 4)
		winning = WINNING_SMALL
		to_chat(user, span_notice("Winner! You win [PRIZE_SMALL] [MONEY_NAME]!"))
		balloon_alert_to_viewers("Winner!", ignored_mobs = list(user))
		give_money(PRIZE_SMALL)
		user.add_mood_event(SLOTS_MOOD_CATEGORY, /datum/mood_event/slots/win)

	else if(winning_length == 3)
		winning = WINNING_SMALL
		to_chat(user, span_notice("Three in a row! You win [SPIN_PRICE * 2] [MONEY_NAME]!"))
		balloon_alert_to_viewers("Three in a row!", ignored_mobs = list(user))
		balance += SPIN_PRICE * 2
		money -= SPIN_PRICE * 2

	else
		winning = WINNING_NOTHING
		to_chat(user, span_notice("No luck! You lose [SPIN_PRICE] [MONEY_NAME]!"))
		did_player_win = FALSE
		user.add_mood_event(SLOTS_MOOD_CATEGORY, /datum/mood_event/slots/loss)

	playsound(src, 'sound/machines/lever/lever_stop.ogg', 50)

	SStgui.update_uis(src)
	addtimer(CALLBACK(src, PROC_REF(clear_winning)), 3 SECONDS)

	if(did_player_win)
		add_filter("jackpot_rays", 3, ray_filter)
		animate(get_filter("jackpot_rays"), offset = 10, time = 3 SECONDS, loop = -1)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/datum, remove_filter), "jackpot_rays"), 3 SECONDS)
		playsound(src, 'sound/machines/roulette/roulettejackpot.ogg', 50, TRUE)

/obj/machinery/computer/slot_machine/darkpack/proc/house_access(mob/living/user, obj/item/vamp/keys/key_used)
	if(!key_used.opens_door_in(get_area(src)))
		balloon_alert(user, "wrong key!")
		return
	if(working)
		balloon_alert(user, "still spinning!")
		return
	var/choice = tgui_alert(user, "The machine holds [money] [MONEY_NAME_AUTOPURAL(money)].", name, list("Deposit", "Withdraw"))
	if(!choice || working || !user.can_perform_action(src))
		return
	if(choice == "Deposit")
		var/obj/item/stack/dollar/cash = user.is_holding_item_of_type(/obj/item/stack/dollar)
		if(!cash)
			balloon_alert(user, "no cash in hand!")
			return
		var/amount = tgui_input_number(user, "Amount to deposit:", name, max_value = cash.amount, min_value = 1)
		if(!amount || working || !user.can_perform_action(src))
			return
		if(!cash.use(amount))
			return
		money += amount
		balloon_alert(user, "[amount] [MONEY_NAME_AUTOPURAL(amount)] deposited")
		return
	var/amount = tgui_input_number(user, "Amount to withdraw:", name, max_value = money, min_value = 1)
	if(!amount || working || !user.can_perform_action(src))
		return
	amount = min(amount, money)
	if(amount <= 0)
		return
	money -= amount
	user.put_in_hands(new /obj/item/stack/dollar(drop_location(), amount))
	balloon_alert(user, "[amount] [MONEY_NAME_AUTOPURAL(amount)] withdrawn")

#undef SPIN_PRICE
#undef WINNING_NOTHING
#undef WINNING_SMALL
#undef WINNING_BIG
#undef WINNING_JACKPOT
#undef PRIZE_SMALL
#undef PRIZE_BIG
#undef PRIZE_JACKPOT
