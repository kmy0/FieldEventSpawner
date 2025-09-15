local config = require("FieldEventSpawner.config.init")
local config_menu = require("FieldEventSpawner.gui.init")
local data = require("FieldEventSpawner.data.init")
local sched = require("FieldEventSpawner.schedule.init")
local util = require("FieldEventSpawner.util.init")
local logger = util.misc.logger.g

---@class MethodUtil
local m = util.ref.methods

local init = util.misc.init_chain:new("MAIN", config.init, data.init, sched.init, data.runtime.init)

m.getEnemyNameGuid = m.wrap(m.get("app.EnemyDef.EnemyName(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Guid]]
m.getRewardRankFromDifficulty =
    m.wrap(m.get("app.EnemyUtil.getRewardRankFromDifficulty(System.Guid)")) --[[@as fun(guid:  System.Guid): app.QuestDef.EM_REWARD_RANK]]
m.isBossID = m.wrap(m.get("app.EnemyDef.isBossID(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Boolean]]
m.isEmValid = m.wrap(m.get("app.EnemyDef.isValid(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Boolean]]
m.getEnemyLegendaryName = m.wrap(m.get("app.EnemyDef.EnemyLegendaryName(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Guid]]
m.getEnemyLegendaryKingName = m.wrap(m.get("app.EnemyDef.EnemyLegendaryKingName(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Guid]]
m.getEnemyFrenzyName = m.wrap(m.get("app.EnemyDef.EnemyFrenzyName(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Guid]]
m.getEnemyExtraName = m.wrap(m.get("app.EnemyDef.EnemyExtraName(app.EnemyDef.ID)")) --[[@as fun(em_id: app.EnemyDef.ID): System.Guid]]
m.getGimmickEventName = m.wrap(m.get("app.ExDef.Name(app.ExDef.GIMMICK_EVENT)")) --[[@as fun(gm_ev: app.ExDef.GIMMICK_EVENT): System.Guid]]
m.getAnimalEventName = m.wrap(m.get("app.ExDef.AnimalEventName(app.ExDef.ANIMAL_EVENT)")) --[[@as fun(am_ev: app.ExDef.ANIMAL_EVENT): System.Guid]]
m.getGimmickID = m.wrap(m.get("app.ExDef.GimmickID(app.ExDef.GIMMICK_EVENT)")) --[[@as fun(gm_ev: app.ExDef.GIMMICK_EVENT): app.GimmickDef.ID]]
m.createEventInstance =
    m.wrap(m.get("app.ExFieldUtil.createEventInstance(app.cExFieldScheduleExportData.cEventData)")) --[[@as fun(ev_data: app.cExFieldScheduleExportData.cEventData): app.cExFieldEventBase]]
m.getItemData = m.wrap(m.get("app.ItemDef.Data(app.ItemDef.ID)")) --[[@as fun(item_id: app.ItemDef.ID): app.user_data.ItemData.cData]]
m.isValidItem = m.wrap(m.get("app.ItemDef.isValidItem(app.ItemDef.ID)")) --[[@as fun(item_id: app.ItemDef.ID): System.Boolean]]
m.getIncorrectStatusBit =
    m.wrap(m.get("app.QuestCheckUtil.getIncorrectStatusBit(app.QuestCheckUtil.INCORRECT_STATUS)")) --[[@as fun(status: app.QuestCheckUtil.INCORRECT_STATUS): System.Int32]]

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

re.on_config_save(config.save_no_timer_global)
