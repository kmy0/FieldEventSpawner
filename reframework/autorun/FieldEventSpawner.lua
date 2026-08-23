local config = require("FieldEventSpawner.config.init")
local config_menu = require("FieldEventSpawner.gui.init")
local data = require("FieldEventSpawner.data.init")
local init_chain = require("FieldEventSpawner.config.init_chain")
local sched = require("FieldEventSpawner.schedule.init")
local util = require("FieldEventSpawner.util.init")
local logger = util.misc.logger.g

---@class MethodUtil
local m = util.ref.methods

local init =
    init_chain:new("MAIN", config.init, data.init, sched.init, data.mod.init, config_menu.init)

m.getEnemyNameGuid = m.wrap(m.get("app.EnemyDef.EnemyName(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Guid]]
m.getRewardRankFromDifficulty =
    m.wrap(m.get("app.EnemyUtil.getRewardRankFromDifficulty(System.Guid)")) --[[@as fun(guid:  System.Guid): app.QuestDef.EM_REWARD_RANK]]
m.isBossID = m.wrap(m.get("app.EnemyDef.isBossID(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Boolean]]
m.isEmValid = m.wrap(m.get("app.EnemyDef.isValid(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Boolean]]
m.getGimmickEventName = m.wrap(m.get("app.ExDef.Name(app.ExDef.GIMMICK_EVENT)")) --[[@as fun(gm_ev: app.ExDef.GIMMICK_EVENT): System.Guid]]
m.getAnimalEventName = m.wrap(m.get("app.ExDef.AnimalEventName(app.ExDef.ANIMAL_EVENT)")) --[[@as fun(am_ev: app.ExDef.ANIMAL_EVENT): System.Guid]]
m.getGimmickID = m.wrap(m.get("app.ExDef.GimmickID(app.ExDef.GIMMICK_EVENT)")) --[[@as fun(gm_ev: app.ExDef.GIMMICK_EVENT): app.GimmickDef.ID]]
m.createEventInstance =
    m.wrap(m.get("app.ExFieldUtil.createEventInstance(app.cExFieldScheduleExportData.cEventData)")) --[[@as fun(ev_data: app.cExFieldScheduleExportData.cEventData): app.cExFieldEventBase]]
m.getItemData = m.wrap(m.get("app.ItemDef.Data(app.ItemDef.ID)")) --[[@as fun(item_id: app.ItemDef.ID): app.user_data.ItemData.cData]]
m.isValidItem = m.wrap(m.get("app.ItemDef.isValidItem(app.ItemDef.ID)")) --[[@as fun(item_id: app.ItemDef.ID): System.Boolean]]
m.getIncorrectStatusBit =
    m.wrap(m.get("app.QuestCheckUtil.getIncorrectStatusBit(app.QuestCheckUtil.INCORRECT_STATUS)")) --[[@as fun(status: app.QuestCheckUtil.INCORRECT_STATUS): System.Int32]]
m.realSec_to_GameMinute = m.wrap(m.get("app.ExFieldUtil.realSec_to_GameMinute(System.Single)")) --[[@as fun(sec: System.Single): System.Single]]
m.getEnemyName = m.wrap(
    m.get("app.EnemyDef.Name(app.EnemyDef.ID, app.EnemyDef.ROLE_ID, app.EnemyDef.LEGENDARY_ID)")
) --[[@as fun(em_id: app.EnemyDef.ID, role_id: app.EnemyDef.ROLE_ID, legendary_id: app.EnemyDef.LEGENDARY_ID): System.Guid]]
m.getStageNameGuid =
    m.wrap(m.get("app.GUIUtilApp.MapUtil.getStageFullName(app.FieldDef.STAGE, System.Guid)")) --[[@as fun(stage: app.FieldDef.STAGE, guid_ptr: integer): System.Boolean]]
m.checkExQuest = m.wrap(m.get("app.QuestCheckUtil.checkExQuest(System.Int32, app.cKeepQuestData)")) --[[@as fun(out_bit: System.Int32, quest_data: app.cKeepQuestData): System.Boolean]]
m.createActiveQuestData_Instant = m.wrap(
    m.get(
        "app.QuestUtil.createActiveQuestData_Instant(app.cExFieldEvent_PopEnemy, app.FieldDef.STAGE)"
    )
) --[[@as fun(pop_em: app.cExFieldEvent_PopEnemy, stage: app.FieldDef.STAGE): app.cActiveQuestData]]
m.createBossContextSaveParam_Keep =
    m.wrap(m.get("app.savedata.cBoss_ContextSaveParam_KeepQuest.create()")) --[[@as fun(): app.savedata.cBoss_ContextSaveParam_KeepQuest]]
m.getMissionRewards = m.wrap(
    m.get(
        "app.QuestRewardUtil.getRewardItemData(app.MissionIDList.ID, app.cQuestDirector.TIME_RANK, System.Int32)"
    )
) --[[@as fun(quest_id: app.MissionIDList.ID, time_rank: app.cQuestDirector.TIME_RANK, bonus_reward_roll_count: System.Int32): System.Array<app.cGUIRewardItems>]]
m.createQuestTitleMessage = m.wrap(m.get("app.MessageUtil.createMessage(ace.cGUIMessageInfo)")) --[[@as fun(msg: ace.cGUIMessageInfo): System.String]]
m.getRewardItemDataList = m.wrap(
    m.get(
        "app.QuestGeneralRewardUtil.getRewardItemDataList(app.user_data.QuestGeneralRewardData, System.UInt32)"
    )
) --[[@as fun(user_data: app.user_data.QuestGeneralRewardData, table_id: System.UInt32): app.QuestGeneralRewardUtil.QuestRewardLotsData]]

m.hook(
    "app.QuestCheckUtil.checkExQuest(System.Int32, app.cKeepQuestData)",
    sched.hook.allow_invalid_quests_pre,
    sched.hook.allow_invalid_quests_post
)
m.hook(
    "app.QuestCheckUtil.checkExQuest(System.Int32, app.net_session_manager.SessionManager.cSearchResultQuest)",
    sched.hook.allow_invalid_quests_pre,
    sched.hook.allow_invalid_quests_post
)
m.hook(
    "app.cExFieldEvent_PopEnemy.checkPopEnabled(System.Boolean, System.Boolean, "
        .. "System.Collections.Generic.List`1<System.Int32>, System.Int32, System.Int32, System.Int32)",
    nil,
    sched.hook.spawn_check_post
)
m.hook(
    "app.cEmModuleCombatEm.isAcceptCombatEm_CheckFeelTarget"
        .. "(app.cEnemyContextHolder, app.EnemyCharacter, app.cEmModuleCombatEm.cTargetInfo, "
        .. "app.cEnemyContextHolder, System.Boolean, System.Boolean)",
    sched.hook.stop_em_combat_pre,
    sched.hook.stop_em_combat_post
)
m.hook(
    "app.cContextInstanceController_Enemy.onSetupContext(app.cContextCreateArg)",
    sched.hook.force_context_area_pre
)
m.hook(
    "app.cExFieldDirector.update",
    sched.hook.ex_director_update_pre,
    sched.hook.ex_director_update_post
)
m.hook("app.cExFieldDirector.saveSchedule_CurrentStage", sched.hook.ex_director_save_sched_pre)
m.hook("app.SaveDataManager.requestSaveDataLoad", nil, sched.hook.on_game_load_post)
m.hook("app.SaveDataManager.systemRequestSystemSave", nil, sched.hook.on_game_save_post)
m.hook(
    "app.cAnimalExManager.loadExEventSet(app.FieldDef.STAGE, app.ExDef.ANIMAL_EVENT, System.Int32)",
    nil,
    sched.hook.spawn_check_post
)
m.hook(
    "app.user_data.ExFieldParam.cEnvEventGlobalParam.isNotifyGimmick(app.ExDef.GIMMICK_EVENT)",
    nil,
    sched.hook.spawn_check_post
)
m.hook(
    "app.user_data.ExFieldParam.cEnvEventGlobalParam.isNotifyAnimal(app.ExDef.ANIMAL_EVENT)",
    nil,
    sched.hook.spawn_check_post
)
m.hook(
    "app.cExFieldEvent_GimmickEvent.executeProc(System.Int32)",
    nil,
    sched.hook.gimmick_execute_post
)
m.hook(
    "app.cExSpOfferFactory.createSpOffer(app.cExSpOfferFactory.cSpOfferByStage, System.Int32, "
        .. "System.Boolean, app.FieldDef.STAGE, System.Boolean, System.Int32, app.cExFieldEvent_PopEnemy)",
    sched.hook.create_spoffer_pre,
    sched.hook.create_spoffer_post
)
m.hook(
    "app.cExSpOfferFactory.checkCreateSpOffer(app.cExSpOfferFactory.cSpOfferByStage, System.Int32)",
    sched.hook.force_check_spoffer_pre
)
m.hook(
    "app.user_data.ExFieldParam.lotCreateSpOffer(System.Byte, System.Int32)",
    nil,
    sched.hook.force_lot_spoffer_post
)
m.hook("app.user_data.ExFieldParam.lotIsVillageBoost", nil, sched.hook.spoffer_village_boost_post)
m.hook("app.cExFieldDirector.findExecutedPopEms", nil, sched.hook.force_spoffer_array_post)
m.hook("app.cExFieldDirector.findExecutedPopEms", nil, sched.hook.filter_spoffer_array_post)
m.hook(
    "app.cExFieldDirector.recreateEmPopEvent_BeforeExecute(app.cExFieldEvent_PopEnemy, "
        .. "app.cExFieldEvent_PopEnemy, System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Boolean)",
    sched.hook.force_pop_many_spawn_pre,
    sched.hook.force_pop_many_spawn_post
)
m.hook(
    "app.cExFieldDirector.relotEmReward(app.cExFieldDirector.cScheduleTimeline, app.cExFieldEvent_PopEnemy, "
        .. "System.Collections.Generic.List`1<app.cExFieldEvent_EmReward>, app.FieldDef.STAGE)",
    sched.hook.force_pop_many_reward_pre
)
m.hook(
    "app.EnemyUtil.lotteryModelRandomSize_Boss(app.EnemyDef.ID, app.EnemyDef.LEGENDARY_ID, System.Guid, app.cRandomHolder)",
    nil,
    sched.hook.force_em_size_post
)
m.hook(
    "app.user_data.ExFieldParam_EnemyData.isExclusiveEm(app.EnemyDef.ID)",
    nil,
    sched.hook.exclusive_em_check_post
)
m.hook(
    "app.cExFieldDirector.update(app.cExFieldDirector.RUN_ORDER, app.FieldDef.STAGE, System.Int32, System.Int32, System.Single)",
    sched.hook.pause_schedule_pre
)
m.hook(
    "app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm.lotCreateSpOffer(System.Byte, System.Single)",
    nil,
    sched.hook.force_lot_spoffer_swarm_post
)
m.hook(
    "app.cExSpOfferFactory.saveSpOffer(app.cExSpOfferFactory.cSpOfferByStage, System.Boolean, app.savedata.cFieldExParam)",
    nil,
    sched.hook.create_spoffer_swarm_post
)
m.hook("app.cExFieldDirector.init()", nil, data.ace.load_invalid_options)
m.hook(
    "app.QuestUtil.getKeepQuestCost(app.QuestDef.EM_REWARD_RANK, app.EnemyDef.LEGENDARY_ID)",
    nil,
    sched.hook.get_keep_quest_post
)
m.hook("app.cKeepQuestData.getAcceptableHR()", nil, sched.hook.get_accept_hr_post)
m.hook(
    "app.QuestUtil.isEnableExecute_Instant(System.Int32, app.cExFieldEvent_PopEnemy, app.cEnemyContext, System.Boolean, System.Single, System.Boolean)",
    nil,
    sched.hook.is_enable_execute_instant_post
)
m.hook(
    "app.ExQuestRewardUtil.lotSkillGemReward(app.user_data.ExQuestRewardSetting, ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, app.QuestDef.EM_REWARD_RANK, System.Boolean, System.Boolean)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_max_skillgem_post
)
m.hook(
    "app.ExQuestRewardUtil.lotAmuletReward(app.user_data.ExQuestRewardSetting, ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, app.QuestDef.EM_REWARD_RANK, System.Boolean, System.Boolean)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_max_amulet_post
)
m.hook(
    "app.ExQuestRewardUtil.lotArtianReward(app.user_data.ExQuestRewardSetting, ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, app.QuestDef.EM_REWARD_RANK, System.Boolean, System.Boolean)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_max_artian_post
)
m.hook(
    "app.ExQuestRewardUtil.lotExEmReward(System.Collections.Generic.List`1<app.savedata.cItemWork>, System.Collections.Generic.List`1<System.Boolean>, System.Boolean, app.user_data.ExQuestRewardSetting, app.ExQuestRewardUtil.EM_INFO_FOR_REWARD, System.Boolean, System.Boolean, app.QuestDef.EM_REWARD_RANK)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_ax_emreward_post
)
m.hook(
    "app.ExQuestRewardUtil.lotLotNumFromGrade(app.user_data.ExQuestRewardSetting, ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, System.Int32, System.Boolean, System.Boolean, app.QuestDef.EM_REWARD_RANK)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_max_slot_post
)
m.hook(
    "app.user_data.ExQuestRewardSetting.cRewardSlotTable.tryGetWeightedRewardSlot(System.Byte)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_max_slot_spoffer_swarm_post
)
m.hook(
    "app.user_data.ExQuestRewardSetting.cRewardItemTable.tryGetWeightedRewardItem(ace.cLimitedArray`1<app.savedata.cItemWork>, ace.cLimitedArray`1<System.Boolean>, System.Byte[], ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, System.Byte)",
    sched.hook.reward_max_get_args_pre,
    sched.hook.reward_max_reward_spoffer_swarm_post
)
m.hook(
    "app.cExFieldDirector.findExecutedPopEms(System.Boolean, System.Boolean)",
    nil,
    sched.hook.force_spoffer_swarm_em_post
)
m.hook(
    "app.QuestUtil.createKeepQuest(app.cExSpOfferInfo_forView)",
    nil,
    sched.hook.save_spoffer_em_sizes_post
)
m.hook(
    "app.user_data.ExFieldParam_LayoutData.getLegendaryPopParam(app.EnemyDef.ID, app.user_data.ExFieldParam_LayoutData.cEmPopParam_Legendary[])",
    sched.hook.spoof_em_id_spoffer_swarm_pop_param_pre
)
m.hook(
    "app.user_data.ExFieldParam.getFieldLayout(app.FieldDef.STAGE)",
    sched.hook.spoof_stage_id_spoffer_swarm_pre
)
m.hook(
    "app.user_data.ExQuestRewardSetting.tryGetSwarmSpOfferRewardByEm(app.user_data.ExQuestRewardSetting.cSwarmSpOfferRewardByEm, app.EnemyDef.ID)",
    sched.hook.spoof_em_id_spoffer_swarm_rewards_pre
)
m.hook(
    "app.user_data.ExQuestRewardSetting.cRewardItemTable.tryGetWeightedRewardItem(ace.cLimitedArray`1<app.savedata.cItemWork>, ace.cLimitedArray`1<System.Boolean>, System.Byte[], ace.cLimitedArray`1<app.ExQuestRewardUtil.EM_INFO_FOR_REWARD>, System.Byte)",
    nil,
    sched.hook.spoffer_swarm_ignore_empty_reward_post
)
m.hook(
    "app.cExMoreTargetSpOfferFactory.tryCreateSwarmSpOfferProc(app.cExFieldEvent_SpOfferMore, app.cExFieldEvent_SpOfferMore_Target, ace.cLimitedArray`1<app.cExFieldEvent_EmReward>, ace.cLimitedArray`1<app.cExFieldEvent_PopEnemy>, ace.cLimitedArray`1<app.savedata.cItemWork>, System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Int32, app.EnemyDef.ID, app.FieldDef.STAGE)",
    sched.hook.spoffer_swarm_flag_pre,
    sched.hook.spoffer_swarm_flag_post
)
m.hook(
    "app.cExFieldEvent_PopEnemy.executeProc(System.Int32)",
    nil,
    sched.hook.request_spoffer_swarm_post
)
m.hook(
    m.get_by_regex("app.cExSpOfferFactory", "^<createSpOffer>g__isCandidate") --[[@as REMethodDefinition]],
    nil,
    sched.hook.spoffer_is_candidate_post
)
m.hook(
    "app.QuestUtil.getKeepQuestCost(app.cExFieldEvent_PopEnemy[])",
    nil,
    sched.hook.get_keep_quest_post
)

re.on_draw_ui(function()
    if imgui.button(string.format("%s %s", config.name, config.commit)) and init.ok then
        local gui_main = config.gui.current.gui.main
        gui_main.is_opened = not gui_main.is_opened
    end

    if not init.failed then
        local errors = logger:format_errors()
        if errors then
            imgui.same_line()
            imgui.text_colored("Error!", data.gui.colors.bad)
            util.imgui.tooltip_exclamation(errors)
        elseif not init.ok then
            imgui.same_line()
            imgui.text_colored("Initializing...", data.gui.colors.info)
        end
    else
        imgui.same_line()
        imgui.text_colored("Init failed!", data.gui.colors.bad)
        local errors = logger:get_last_error()
        if errors then
            util.imgui.tooltip_exclamation(errors)
        end
    end
end)

re.on_frame(function()
    if not init:init() then
        return
    end

    local config_gui = config.gui.current.gui

    if not reframework:is_drawing_ui() then
        config_gui.main.is_opened = false
    end

    if config_gui.main.is_opened then
        sched.update()
        config_menu.draw()
    end

    config.run_save()
end)

re.on_config_save(function()
    if data.mod.initialized then
        config.save_no_timer_global()
    end
end)
