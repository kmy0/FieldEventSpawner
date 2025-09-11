local config = require("FieldEventSpawner.config")
local lang = require("FieldEventSpawner.lang")

config.init()
lang.init()

local sched = require("FieldEventSpawner.schedule")

sched.init()

local config_menu = require("FieldEventSpawner.gui")

sdk.hook(
    sdk.find_type_definition("app.QuestCheckUtil"):get_method("checkExQuest(System.Int32, app.cKeepQuestData)") --[[@as REMethodDefinition]],
    sched.hook.allow_invalid_quests_pre,
    sched.hook.allow_invalid_quests_post
)
sdk.hook(
    sdk.find_type_definition("app.QuestCheckUtil")
        :get_method("checkExQuest(System.Int32, app.net_session_manager.SessionManager.cSearchResultQuest)") --[[@as REMethodDefinition]],
    sched.hook.allow_invalid_quests_pre,
    sched.hook.allow_invalid_quests_post
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldEvent_PopEnemy"):get_method("checkPopEnabled") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.spawn_check_post
)
sdk.hook(
    sdk.find_type_definition("app.cEmModuleCombatEm"):get_method(
        "isAcceptCombatEm_CheckFeelTarget(app.cEnemyContextHolder, app.EnemyCharacter, app.cEmModuleCombatEm.cTargetInfo, app.cEnemyContextHolder, System.Boolean, System.Boolean)"
    ) --[[@as REMethodDefinition]],
    sched.hook.stop_em_combat_pre,
    sched.hook.stop_em_combat_post
)
sdk.hook(
    sdk.find_type_definition("app.cContextInstanceController_Enemy"):get_method("onSetupContext(app.cContextCreateArg)") --[[@as REMethodDefinition]],
    sched.hook.force_context_area_pre
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldDirector"):get_method("update") --[[@as REMethodDefinition]],
    sched.hook.ex_director_update_pre,
    sched.hook.ex_director_update_post
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldDirector"):get_method("saveSchedule_CurrentStage") --[[@as REMethodDefinition]],
    sched.hook.ex_director_save_sched_pre
)
sdk.hook(
    sdk.find_type_definition("app.SaveDataManager"):get_method("requestSaveDataLoad") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.on_game_load_post
)
sdk.hook(
    sdk.find_type_definition("app.SaveDataManager"):get_method("systemRequestSystemSave") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.on_game_save_post
)
sdk.hook(
    sdk.find_type_definition("app.cAnimalExManager")
        :get_method("loadExEventSet(app.FieldDef.STAGE, app.ExDef.ANIMAL_EVENT, System.Int32)") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.spawn_check_post
)
sdk.hook(
    sdk.find_type_definition("app.user_data.ExFieldParam.cEnvEventGlobalParam")
        :get_method("isNotifyGimmick(app.ExDef.GIMMICK_EVENT)") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.spawn_check_post
)
sdk.hook(
    sdk.find_type_definition("app.user_data.ExFieldParam.cEnvEventGlobalParam")
        :get_method("isNotifyAnimal(app.ExDef.ANIMAL_EVENT)") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.spawn_check_post
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldEvent_GimmickEvent"):get_method("executeProc(System.Int32)") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.gimmick_execute_post
)
sdk.hook(
    sdk.find_type_definition("app.cExSpOfferFactory"):get_method(
        "createSpOffer(app.cExSpOfferFactory.cSpOfferByStage, System.Int32, System.Boolean, app.FieldDef.STAGE, System.Boolean, System.Int32, app.cExFieldEvent_PopEnemy)"
    ) --[[@as REMethodDefinition]],
    sched.hook.create_spoffer_pre,
    sched.hook.create_spoffer_post
)
sdk.hook(
    sdk.find_type_definition("app.cExSpOfferFactory")
        :get_method("checkCreateSpOffer(app.cExSpOfferFactory.cSpOfferByStage, System.Int32)") --[[@as REMethodDefinition]],
    sched.hook.force_check_spoffer_pre
)
sdk.hook(
    sdk.find_type_definition("app.user_data.ExFieldParam"):get_method("lotCreateSpOffer(System.Byte, System.Int32)") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.force_lot_spoffer_post
)
sdk.hook(
    sdk.find_type_definition("app.user_data.ExFieldParam"):get_method("lotIsVillageBoost") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.spoffer_village_boost_post
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldDirector"):get_method("findExecutedPopEms") --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.force_spoffer_array_post
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldDirector"):get_method(
        "recreateEmPopEvent_BeforeExecute(app.cExFieldEvent_PopEnemy, app.cExFieldEvent_PopEnemy, System.Collections.Generic.List`1<app.cExFieldEvent_PopEnemy>, System.Boolean)"
    ) --[[@as REMethodDefinition]],
    sched.hook.force_pop_many_spawn_pre,
    sched.hook.force_pop_many_spawn_post
)
sdk.hook(
    sdk.find_type_definition("app.cExFieldDirector"):get_method(
        "relotEmReward(app.cExFieldDirector.cScheduleTimeline, app.cExFieldEvent_PopEnemy, System.Collections.Generic.List`1<app.cExFieldEvent_EmReward>, app.FieldDef.STAGE)"
    ) --[[@as REMethodDefinition]],
    sched.hook.force_pop_many_reward_pre
)
sdk.hook(
    sdk.find_type_definition("app.EnemyUtil"):get_method(
        "lotteryModelRandomSize_Boss(app.EnemyDef.ID, app.EnemyDef.LEGENDARY_ID, System.Guid, app.cRandomHolder)"
    ) --[[@as REMethodDefinition]],
    function(args) end,
    sched.hook.force_em_size_post
)

re.on_draw_ui(function()
    if imgui.button(string.format("%s %s", config.name, config.version)) then
        config.current.gui.main.is_opened = not config.current.gui.main.is_opened
    end
end)

re.on_frame(function()
    if not reframework:is_drawing_ui() then
        config.current.gui.main.is_opened = false
    end

    if config.current.gui.main.is_opened then
        sched.update()
        config_menu.draw()
    end
end)

re.on_config_save(config.save)
