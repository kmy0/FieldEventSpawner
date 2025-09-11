---@meta

---@class app.cGameContext : via.clr.ManagedObject
---@class app.AppBehavior : via.Behavior
---@class app.cPlayerManageInfo : via.clr.ManagedObject
---@class app.user_data.ExFieldParam_LayoutData.cDifficultyWeight : via.clr.ManagedObject
---@class app.user_data.ExFieldParam_LayoutData.cEmPopParam_Common: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base
---@class app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_EnvStart : app.user_data.ExFieldParam_LayoutData.cEmPopParam_Common
---@class app.user_data.ExFieldParam_LayoutData.cDifficultyWeight : via.clr.ManagedObject
---@class app.user_data.ExFieldParam_LayoutData.cEmPopParamByHR_Base : via.clr.ManagedObject
---@class app.cParamsByEnv<app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv>
---@class app.cExFieldEvent_Battlefield : app.cExFieldEventBase
---@class app.cExFieldEvent_AnimalEvent : app.cExFieldEventBase
---@class app.EnemyCharacter : app.CharacterBase
---@class app.cAnimalNoUpdatableSystem: via.clr.ManagedObject
---@class app.GimmickManagerBase : ace.GAElement
---@class app.cExSpOfferFactory.SpOfferInfo : System.ValueType
---@class app.cGameContextHolder : via.clr.ManagedObject
---@class app.cEmModuleBase : via.clr.ManagedObject
---@class app.cContextCreateArg : via.clr.ManagedObject
---@class app.cExFieldEvent_SpecialOffer : app.cExFieldEventBase
---@class app.cEmParamGuid_RandomSize_RandomSizeTbl : app.cEmParamGuidBase

---@class app.GUIManager : ace.GUIManagerBase
---@field getSystemLanguageToApp fun(self: app.GUIManager) : via.Language

---@class app.cNpcContext : app.cGameContext
---@field NpcID app.NpcDef.ID

---@class app.PlayerManager : ace.GAElement
---@field getMasterPlayer fun(self: app.PlayerManager): app.cPlayerManageInfo

-- some pop_param inheritance things are wrong, not sure if this mess can be translated properly to luals
---@class app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base : app.cParamByEnvBase
---@field get_RandomWeight fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base): System.Byte

---@class app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm : app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_EnvStart
---@field get_IsBossSpawned fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm): System.Boolean
---@field lotDifficultyID_Boss fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm, legendary_id: app.EnemyDef.LEGENDARY_ID, suitable_only: System.Boolean): System.Guid
---@field get_BossLegendaryProbability fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Swarm): System.Byte
---@field _BossDifficultyParams System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>

---@class app.user_data.ExFieldParam_LayoutData.cEmPopParam_Legendary : app.user_data.ExFieldParam_LayoutData.cEmPopParam_Common
---@field get_BossProbability fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Legendary): System.Byte

---@class app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base : via.clr.ManagedObject
---@field _DifficultyParams System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
---@field _ParamsByEnv app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base
---@field checkSuitableDifficulty fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base, guid: System.Guid): System.Boolean
---@field lotDifficultyID fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base, legendary_id: app.EnemyDef.LEGENDARY_ID, bias: System.Int32, suitable_only: System.Boolean): System.Guid
---@field get_LegendaryProbability fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base): System.Byte

---@class app.user_data.ExFieldParam_LayoutData.cEnvEventParamBase : via.clr.ManagedObject
---@field getRandomWeight fun(self: app.user_data.ExFieldParam_LayoutData.cEnvEventParamBase, stage: app.FieldDef.STAGE, env: app.EnvironmentType.ENVIRONMENT): System.Byte

---@class app.user_data.ExFieldParam_LayoutData.cGimmickEventParam : app.user_data.ExFieldParam_LayoutData.cEnvEventParamBase
---@field get_GimmickEvent fun(self: app.user_data.ExFieldParam_LayoutData.cGimmickEventParam): app.ExDef.GIMMICK_EVENT

---@class app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea : via.clr.ManagedObject
---@field get_GimmickEvents fun(self: app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea): System.Array<app.user_data.ExFieldParam_LayoutData.cGimmickEventParam>
---@field get_AnimalEvents fun(self: app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea): System.Array<app.user_data.ExFieldParam_LayoutData.cAnimalEventParam>
---@field get_AreaNo fun(self: app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea): System.Int32
---@field get_AreaID_Fixed fun(self: app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea): app.FieldDef.AREA_ID_Fixed

---@class app.user_data.ExFieldParam_LayoutData.cRareTokusanParamByEnv : app.cParamByEnvBase
---@field get_Weight fun(self: app.user_data.ExFieldParam_LayoutData.cRareTokusanParamByEnv): System.Byte

---@class app.user_data.ExFieldParam_LayoutData.cRareTokusanParam : via.clr.ManagedObject
---@field get_GimmickEvent fun(self: app.user_data.ExFieldParam_LayoutData.cRareTokusanParam): app.ExDef.GIMMICK_EVENT
---@field get_AreaNo fun(self: app.user_data.ExFieldParam_LayoutData.cRareTokusanParam): System.Byte
---@field get_AreaID_Fixed fun(self: app.user_data.ExFieldParam_LayoutData.cRareTokusanParam): app.FieldDef.AREA_ID_Fixed
---@field get_ParamsByEnv fun(self: app.user_data.ExFieldParam_LayoutData.cRareTokusanParam): app.cParamsByEnv<app.user_data.ExFieldParam_LayoutData.cRareTokusanParam>

---@class app.user_data.ExFieldParam_LayoutData.cAncientCoinParam : via.clr.ManagedObject
---@field get_AreaNo fun(self: app.user_data.ExFieldParam_LayoutData.cAncientCoinParam): System.Byte
---@field isContainEnvType fun(self: app.user_data.ExFieldParam_LayoutData.cAncientCoinParam, environ: app.EnvironmentType.ENVIRONMENT): System.Boolean
---@field get_AreaID_Fixed fun(self: app.user_data.ExFieldParam_LayoutData.cAncientCoinParam): System.Byte

---@class app.user_data.ExFieldParam_LayoutData : via.UserData
---@field _RareTokusanParams System.Array<app.user_data.ExFieldParam_LayoutData.cRareTokusanParam>
---@field _AncientCoinParams System.Array<app.user_data.ExFieldParam_LayoutData.cAncientCoinParam>
---@field getEmPopParamByHR fun(self: app.user_data.ExFieldParam_LayoutData, hunter_rank: System.Int32, pop_em_type: app.ExDef.POP_EM_TYPE_Fixed): app.user_data.ExFieldParam_LayoutData.cEmPopParamByHR_Base
---@field getPopParamByEmID fun(self: app.user_data.ExFieldParam_LayoutData, enemy_id: app.EnemyDef.ID, params: System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base>): app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base
---@field get_EnvEventLayoutByArea fun(self: app.user_data.ExFieldParam_LayoutData): System.Array<app.user_data.ExFieldParam_LayoutData.cEnvEventLayoutByArea>
---@field get_Stage fun(self: app.user_data.ExFieldParam_LayoutData): app.FieldDef.STAGE
---@field isBanned fun(self: app.user_data.ExFieldParam_LayoutData, em_id: app.EnemyDef.ID, hunter_rank: System.Int32, pop_em_type: app.ExDef.POP_EM_TYPE_Fixed): System.Boolean

---@class app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfoByEm : via.clr.ManagedObject
---@field get_AllAreaMoveInfoArray fun(self: app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfoByEm): System.Array<app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo>

---@class app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam : via.clr.ManagedObject
---@field lotOptionTagIdx fun(self: app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam, stage: app.FieldDef.STAGE, environ_type: app.EnvironmentType.ENVIRONMENT): System.Byte
---@field get_EmID fun(self: app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam): app.EnemyDef.ID
---@field get_RoleID fun(self: app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam): app.EnemyDef.ROLE_ID
---@field get_LegendaryID fun(self: app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam): app.EnemyDef.LEGENDARY_ID
---@field getOptionTagIdx fun(self: app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam, option_balue: System.Int64): System.Byte

---@class app.user_data.ExFieldParam_EnemyData : via.UserData
---@field getExEmGlobalParam fun(self: app.user_data.ExFieldParam_EnemyData, monster_id: app.EnemyDef.ID, role_id: app.EnemyDef.ROLE_ID, legendary_id: app.EnemyDef.LEGENDARY_ID, quest_rank: app.QuestDef.RANK, reward_rank: app.QuestDef.EM_REWARD_RANK): app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam
---@field getAreaMoveInfo fun(self: app.user_data.ExFieldParam_EnemyData, monster_id: app.EnemyDef.ID): app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfoByEm
---@field get_StayMinute fun(self: app.user_data.ExFieldParam_EnemyData): System.Byte
---@field get_ExEnemies fun(self: app.user_data.ExFieldParam_EnemyData): System.Array<app.user_data.ExFieldParam_EnemyData.cExEmGlobalParam>

---@class app.user_data.ExFieldParam.cAssistNpcGimmick : via.clr.ManagedObject
---@field get_GimmickEvent fun(self: app.user_data.ExFieldParam.cAssistNpcGimmick): app.ExDef.GIMMICK_EVENT
---@field get_AreaNo fun(self: app.user_data.ExFieldParam.cAssistNpcGimmick): System.Byte
---@field get_Stage fun(self: app.user_data.ExFieldParam.cAssistNpcGimmick): app.FieldDef.STAGE
---@field get_AreaID_Fixed fun(self: app.user_data.ExFieldParam.cAssistNpcGimmick): app.FieldDef.AREA_ID_Fixed
---@field checkEnableEnvBit fun(self: app.user_data.ExFieldParam.cAssistNpcGimmick, environ_type: app.EnvironmentType.ENVIRONMENT): System.Boolean

---@class app.user_data.ExFieldParam.cAssistNpcParam : via.clr.ManagedObject
---@field _AssistNpcGimmicks System.Array<app.user_data.ExFieldParam.cAssistNpcGimmick>
---@field get_InstanceGuid fun(self: app.user_data.ExFieldParam.cAssistNpcParam): System.Guid
---@field lotIntervalMinute fun(self: app.user_data.ExFieldParam.cAssistNpcParam): System.Byte

---@class app.user_data.ExFieldParam : via.UserData
---@field _FieldLayouts System.Array<app.user_data.ExFieldParam_LayoutData>
---@field _SpOfferSecondTargetWeightsByFirstEmRank System.Array<app.user_data.ExFieldParam.cSpOfferSecondTargetWeightByFirstEmRank>
---@field getFieldLayout fun(self: app.user_data.ExFieldParam, stage: app.FieldDef.STAGE): app.user_data.ExFieldParam_LayoutData
---@field get_ExEnemyGlobalParam fun(self: app.user_data.ExFieldParam): app.user_data.ExFieldParam_EnemyData
---@field isOpenedVillageBoost fun(self: app.user_data.ExFieldParam, stage: app.FieldDef.STAGE): System.Boolean
-- bool doesnt seem to do anything, always called with false
---@field lotIsVillageBoost fun(self: app.user_data.ExFieldParam, monster_id: app.EnemyDef.ID, reward_rank: app.QuestDef.EM_REWARD_RANK, bool: System.Boolean): System.Boolean
---@field get_AssistNpcParams fun(self: app.user_data.ExFieldParam): System.Array<app.user_data.ExFieldParam.cAssistNpcParam>
---@field isOpenedSpOffer fun(self: app.user_data.ExFieldParam, stage: app.FieldDef.STAGE): System.Boolean
---@field isOpenedAssisNpc fun(self: app.user_data.ExFieldParam, gimmick_event: app.ExDef.GIMMICK_EVENT): System.Boolean
---@field isDisableAssistNpc fun(self: app.user_data.ExFieldParam, gimmick_event: app.ExDef.GIMMICK_EVENT): System.Boolean

---@class app.user_data.ExFieldParam.cSpOfferSecondTargetWeightByFirstEmRank : via.clr.ManagedObject
---@field get_FirstEmRank fun(self: app.user_data.ExFieldParam.cSpOfferSecondTargetWeightByFirstEmRank): app.QuestDef.EM_REWARD_RANK
---@field get_SecondTargetWeights fun(self: app.user_data.ExFieldParam.cSpOfferSecondTargetWeightByFirstEmRank): System.Array<app.user_data.ExFieldParam.cSpOfferSecondTargetWeight>

---@class app.user_data.ExFieldParam.cSpOfferSecondTargetWeight : via.clr.ManagedObject
---@field get_EmRank fun(self: app.user_data.ExFieldParam.cSpOfferSecondTargetWeight): app.QuestDef.EM_REWARD_RANK
---@field get_Weight fun(self: app.user_data.ExFieldParam.cSpOfferSecondTargetWeight): System.Byte

---@class app.user_data.VariousDataManagerSetting : via.UserData
---@field get_ExFieldParam fun(self: app.user_data.VariousDataManagerSetting): app.user_data.ExFieldParam

---@class app.VariousDataManager : ace.GAElement
---@field get_Setting fun(self: app.VariousDataManager) : app.user_data.VariousDataManagerSetting

---@class app.cExFieldScheduleExportData : via.clr.ManagedObject
---@field _EventList System.Array<app.cExFieldScheduleExportData.cEventData>

---@class app.EnvironmentManager : ace.GAElement
---@field _ExFieldDirector app.cExFieldDirector
---@field get_ExCurrentStage fun(self: app.EnvironmentManager): app.FieldDef.STAGE
---@field getEnvActiveLayer fun(self: app.EnvironmentManager, stage: app.FieldDef.STAGE): app.EnvironmentManager.FIELD_DATA_LAYER
---@field getEnvironmentType fun(self: app.EnvironmentManager, stage: app.FieldDef.STAGE, option: System.UInt32): app.EnvironmentType.ENVIRONMENT
-- no idea what those bools are, seems to be always called with false, true, turue, false when creating ex events
---@field getOption fun(self: app.EnvironmentManager, layer: app.EnvironmentManager.FIELD_DATA_LAYER, arg2: System.Boolean, arg3: System.Boolean, arg4: System.Boolean, arg4: System.Boolean)
---@field exportExFieldSchedule_Field fun(self: app.EnvironmentManager, stage_id: app.FieldDef.STAGE): app.cExFieldScheduleExportData

---@class app.cExEvent : via.clr.ManagedObject
---@field _UniqueIndex System.Int32

---@class app.cParamByEnvBase : via.clr.ManagedObject
---@field get_EnvType fun(self: app.cParamByEnvBase): app.EnvironmentType.ENVIRONMENT
---@field getParamByEnv fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base, environ: app.EnvironmentType.ENVIRONMENT) : app.user_data.ExFieldParam_LayoutData.cEmPopParamByEnv_Base

---@class app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv : app.cParamByEnvBase
---@field get_AreaNoArray fun(self: app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv): System.Array<System.Byte>

---@class app.cParamsByEnv<T> : via.clr.ManagedObject
---@field _EnvParams System.Array<any>

---@class app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo: via.clr.ManagedObject
---@field _AreaInfoByEnv app.cParamsByEnv<app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo.cAreaInfoByEnv>
---@field get_AreaMoveGuid fun(self: app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo): System.Guid
---@field get_Stage fun(self: app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo): app.FieldDef.STAGE

---@class app.cExFieldDirector.cScheduleTimeline : via.clr.ManagedObject
---@field _KeyList System.Array<app.cExFieldEventBase>
---@field _CurrentIndex System.Int32
---@field get_KeyList fun(self: app.cExFieldDirector.cScheduleTimeline): System.Array<app.cExFieldEventBase>
---@field get_AdvancedGameMinute fun(self: app.cExFieldDirector.cScheduleTimeline): System.Int32
---@field newSerialEventUniqueIndex fun(self: app.cExFieldDirector.cScheduleTimeline): System.Int32
---@field addKeyRange fun(self: app.cExFieldDirector.cScheduleTimeline, event_list: System.Array<app.cExFieldEventBase>)
---@field newEventUniqueIndex fun(self: app.cExFieldDirector.cScheduleTimeline, stage: app.FieldDef.STAGE): System.Int32
---@field findKeyFromUniqueIndex fun(self: app.cExFieldDirector.cScheduleTimeline, index: System.Int32): app.cExFieldEventBase
---@field importSchedule fun(self: app.cExFieldDirector.cScheduleTimeline, schedule: app.cExFieldScheduleExportData, dont_reset_current_index: System.Boolean)
---@field get_RemainGameMinute fun(self: app.cExFieldDirector.cScheduleTimeline): System.Int32
---@field get_AdvancedRealSec fun(self: app.cExFieldDirector.cScheduleTimeline): System.Single

---@class app.QuestDef.EM_REWARD_RANK : System.Enum
---@class ace.cSaveDataBase : via.clr.ManagedObject
---@class ace.cSaveDataParam : ace.cSaveDataBase
---@class app.savedata.cItemWork : ace.cSaveDataParam
---@class app.cExFieldEvent_EmReward : app.cExFieldEventBase
---@class app.cExFieldDirector : via.clr.ManagedObject
---@field _ScheduleTimeline app.cExFieldDirector.cScheduleTimeline
---@field update_SortKeyList fun(self: app.cExFieldDirector)
-- bool doesnt seem to do anything?
---@field requestSortKeyList fun(self: app.cExFieldDirector, stage: app.FieldDef.STAGE, bool: System.Boolean)
-- last arg: if size of the System.LimitedArray returned by app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfoByEm.getAreaMoveInfoList(app.FieldDef.STAGE, app.user_data.EmParamAreaMove.cPatternData.FOR_EX_ATTR)
-- is bigger than the arg then it tries to trim it down?? im confused af on this one
-- last arg seems to be always 1
---@field getRoutePatternList fun(self: app.cExFieldDirector, enemy_id: app.EnemyDef.ID, enemy_role: app.EnemyDef.ROLE_ID, legendary_id: app.EnemyDef.LEGENDARY_ID, pop_em_type: app.ExDef.POP_EM_TYPE_Fixed, stage_id: app.FieldDef.STAGE, environ_type: app.EnvironmentType.ENVIRONMENT, active_em: System.Array<app.cExFieldEvent_PopEnemy>, arg: System.Int32): System.LimitedArray<app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo>
---@field findExecutedPopEms fun(self: app.cExFieldDirector, quest_available_only: System.Boolean): System.Array<app.cExFieldEvent_PopEnemy>
---@field getInitAreaList fun(self: app.cExFieldDirector, route_info: app.user_data.ExFieldParam_EmAreaMove.cAreaMoveInfo, stage: app.FieldDef.STAGE, environ_type: app.EnvironmentType.ENVIRONMENT): System.LimitedArray<System.Byte>
---@field createExEmRewardEvent fun(self: app.cExFieldDirector, out_reward_array: System.Array<app.cExFieldEvent_EmReward>, out_reward_id_array: System.Array<System.Int32>, size: System.Int32, item_work_array: System.Array<app.savedata.cItemWork>, bool_array: System.Array<System.Boolean>, schedule_timeline: app.cExFieldDirector.cScheduleTimeline, stage_id: app.FieldDef.STAGE)
-- is_legendary specifically checks if its NORMAL
---@field createRewardData fun(self: app.cExFieldDirector, out_item_array: System.Array<app.savedata.cItemWork>, out_bool_array: System.Array<System.Boolean>, enemy_id: app.EnemyDef.ID, monster_role: app.EnemyDef.ROLE_ID, legendary_id: app.EnemyDef.LEGENDARY_ID, difficulty: System.Guid, is_yummy: System.Boolean)
---@field isExEnableStage fun(self: app.cExFieldDirector, stage: app.FieldDef.STAGE): System.Boolean
---@field clearExEventByStage fun(self: app.cExFieldDirector, stage: app.FieldDef.STAGE)
---@field rebuildExEventByStage fun(self: app.cExFieldDirector, stage: app.FieldDef.STAGE, future_only: System.Boolean)
---@field get_IsRun fun(self: app.cExFieldDirector): System.Boolean
---@field destroyAllExEm fun(self: app.cExFieldDirector)
---@field getEnvStartInfoList fun(self: app.cExFieldDirector, out: System.Array<app.cExFieldDirector.ENV_START_INFO>, remain_game_min: System.Int32, advanced_game_min: System.Int32, advanced_real_sec: System.Single, stage: app.FieldDef.STAGE)
---@field get_IsRunBackGround fun(self: app.cExFieldDirector): System.Boolean
---@field get_LoadedStage fun(self: app.cExFieldDirector): System.Boolean

---@class app.cExFieldDirector.ENV_START_INFO : System.ValueType
---@field get_EnvType fun(self: app.cExFieldDirector.ENV_START_INFO): app.EnvironmentType.ENVIRONMENT

---@class app.cExFieldEventBase : app.cExEvent
---@field _ExecMinute System.Int32
---@field _FreeValue0 System.Int32
---@field _FreeValue1 System.Int32
---@field _FreeValue2 System.Int32
---@field _FreeValue3 System.Int32
---@field _FreeValue4 System.Int32
---@field _FreeValue5 System.Int32
---@field _FreeMiniValue0 System.Byte
---@field _FreeMiniValue1 System.Byte
---@field _FreeMiniValue2 System.Byte
---@field _FreeMiniValue3 System.Byte
---@field _FreeMiniValue4 System.Byte
---@field _FreeMiniValue5 System.Byte
---@field _FreeMiniValue6 System.Byte
---@field get_ExFieldEventType fun(self: app.cExFieldEventBase): app.EX_FIELD_EVENT_TYPE
---@field get_IsWorking fun(self: app.cExFieldEventBase): System.Boolean
---@field get_IsActive fun(self: app.cExFieldEventBase): System.Boolean
---@field exportData fun(self: app.cExFieldEventBase): app.cExFieldScheduleExportData.cEventData
---@field get_AreaNo fun(self: app.cExFieldEventBase): System.Byte
---@field endProc fun(self: app.cExFieldEventBase)

---@class app.cExFieldEvent_GimmickEvent : app.cExFieldEventBase
---@field get_IsAssistNpc fun(self: app.cExFieldEvent_GimmickEvent): System.Boolean

---@class app.cExFieldEvent_PopEnemy : app.cExFieldEventBase
---@field requestExit fun(self: app.cExFieldEvent_PopEnemy)
---@field get_IsRequestedExit fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field get_EmID fun(self: app.cExFieldEvent_PopEnemy): app.EnemyDef.ID
---@field get_GroupIDNo fun(self: app.cExFieldEvent_PopEnemy): System.Int32
---@field get_IsSwarm fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field get_IsNushi fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field get_IsLegendary fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field get_IsBattlefieldEm fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field get_PopEmType fun(self: app.cExFieldEvent_PopEnemy): app.ExDef.POP_EM_TYPE_Fixed
---@field get_EnableSpOfferTarget fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field get_EnableKeepQuestTarget fun(self: app.cExFieldEvent_PopEnemy): System.Boolean
---@field findEm fun(self: app.cExFieldEvent_PopEnemy): app.cEnemyContextHolder
---@field get_Rank fun(self: app.cExFieldEvent_PopEnemy): app.QuestDef.EM_REWARD_RANK

---@class app.cExFieldScheduleExportData.cEventData : app.cExEvent
---@field _EventType app.EX_FIELD_EVENT_TYPE
---@field _ExecMinute System.Int32
---@field _FreeValue0 System.Int32
---@field _FreeValue1 System.Int32
---@field _FreeValue2 System.Int32
---@field _FreeValue3 System.Int32
---@field _FreeValue4 System.Int32
---@field _FreeValue5 System.Int32
---@field _FreeMiniValue0 System.Byte
---@field _FreeMiniValue1 System.Byte
---@field _FreeMiniValue2 System.Byte
---@field _FreeMiniValue3 System.Byte
---@field _FreeMiniValue4 System.Byte
---@field _FreeMiniValue5 System.Byte
---@field _FreeMiniValue6 System.Byte

---@class app.cExFieldDirector.cSpawnableEmParam : via.clr.ManagedObject
---@field get_EmID fun(self: app.cExFieldDirector.cSpawnableEmParam): app.EnemyDef.ID
---@field get_StayMinute_Real fun(self: app.cExFieldDirector.cSpawnableEmParam): System.Int32

---@class app.user_data.ExFieldParam_LayoutData.cAnimalEventParam : app.user_data.ExFieldParam_LayoutData.cEnvEventParamBase
---@field get_AnimalEvent fun(self: app.user_data.ExFieldParam_LayoutData.cAnimalEventParam): app.ExDef.ANIMAL_EVENT

---@class app.GameFlowManager : ace.GAElement
---@field get_CurrentGameScene fun(self: app.GameFlowManager) : app.cFieldSceneParam.SCENE_TYPE
---@field get_NextGameStateType fun(self: app.GameFlowManager) : app.cFieldSceneParam.SCENE_TYPE?

---@class app.MasterFieldManager : ace.GAElement
---@field get_CurrentStage fun(self: app.MasterFieldManager): app.FieldDef.STAGE
---@field isLoadedCurrentStage fun(self: app.MasterFieldManager): System.Boolean

---@class app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam : via.clr.ManagedObject
---@field get_AreaNo fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam): System.Byte
---@field get_OptionTagValue fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam): System.Int64

---@class app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield : app.user_data.ExFieldParam_LayoutData.cEmPopParam_Base
---@field _PopBelongingStageParam System.Array<app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam>
---@field _DifficultyParams_PopBelonging System.Array<app.user_data.ExFieldParam_LayoutData.cDifficultyWeight>
---@field get_RouteID fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Guid
---@field get_AreaNo fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Byte
---@field get_RouteID_AfterPopBelongingStage fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Guid
---@field get_AreaNo_AfterPopBelongingStage fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Byte
---@field get_QuestStage fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Byte
---@field get_IsOnlyPopBelongingStage fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Boolean
---@field get_QuestStage fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Byte
---@field get_OptionTagValue fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Int64
---@field lotDifficultyID_PopBelonging fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield, legendary_id: app.EnemyDef.LEGENDARY_ID): System.Guid
---@field getLotPopBelongingStageParam fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield.cPopBelongingStageParam
---@field get_OptionTagValue_AfterPopBelongingStage fun(self: app.user_data.ExFieldParam_LayoutData.cEmPopParam_Battlefield): System.Int64

---@class app.CharacterBase : app.AppBehavior
---@field get_GameObject fun(self: app.CharacterBase) : via.GameObject

---@class app.AnimalManager : ace.GAElement
---@field get_ExManager fun(self: app.AnimalManager): app.AnimalExManager

---@class app.AnimalExManager : app.cAnimalNoUpdatableSystem
---@field unloadAllExEventSet fun(self: app.AnimalExManager)

---@class app.GimmickManager : app.GimmickManagerBase
---@field findGimmick_ID fun(self: app.GimmickManager, gimmick_id: app.GimmickDef.ID): System.Array<app.GimmickBaseApp>

---@class app.cFielAreaInfo : via.clr.ManagedObject
---@field get_MapAreaNumSafety fun(self: app.cFielAreaInfo): System.Int32

---@class app.cGimmickContext : app.cGameContext
---@field get_FieldAreaInfo fun(self: app.cGimmickContext): app.cFielAreaInfo

---@class app.GimmickBaseApp : ace.GimmickBase
---@field get_GimmickContext fun(self: app.GimmickBaseApp): app.cGimmickContext

---@class app.MissionManager : ace.GAElement
---@field get_IsActiveQuest fun(self: app.MissionManager): System.Boolean

---@class app.cExSpOfferFactory.cSpOfferByStage : via.clr.ManagedObject
---@field get_SpOfferList fun(self: app.cExSpOfferFactory.cSpOfferByStage): System.Array<app.cExSpOfferFactory.SpOfferInfo>
---@field set_LotCreateSpOfferGameMinute fun(self: app.cExSpOfferFactory.cSpOfferByStage, value: System.Int32)
---@field set_IsReserveCreateSpOffer fun(self: app.cExSpOfferFactory.cSpOfferByStage, value: System.Boolean)

---@class app.user_data.ItemData.cData : ace.user_data.ExcelUserData.cData
---@field get_RawName fun(self: app.user_data.ItemData.cData): System.Guid
---@field get_ItemId fun(self: app.user_data.ItemData.cData): app.ItemDef.ID_Fixed

---@class app.EnemyManager : ace.GAElement
---@field get_Setting fun(self: app.EnemyManager): app.user_data.EnemyManagerSetting

---@class app.user_data.EnemyManagerSetting : via.UserData
---@field get_Difficulty2 fun(self: app.user_data.EnemyManagerSetting): app.user_data.EmParamDifficulty2
---@field get_RandomSize fun(self: app.user_data.EnemyManagerSetting): app.user_data.EmParamRandomSize
---@field get_Size fun(self: app.user_data.EnemyManagerSetting): app.user_data.EmParamSize

---@class app.user_data.EmParamRandomSize : via.UserData
---@field _EnemyRandomSizeTblArray System.Array<app.user_data.EmParamRandomSize.cEnemyTableData>
---@field getRandomSizeTblData fun(self: app.user_data.EmParamRandomSize, guid: System.Guid): app.user_data.EmParamRandomSize.cRandomSizeData

---@class app.user_data.EmParamRandomSize.cRandomSizeData : via.clr.ManagedObject
---@field _ProbDataTbl System.Array<app.user_data.EmParamRandomSize.cProbData>

---@class app.user_data.EmParamRandomSize.cProbData : via.clr.ManagedObject
---@field get_Prob fun(self: app.user_data.EmParamRandomSize.cProbData): System.UInt16
---@field get_Scale fun(self: app.user_data.EmParamRandomSize.cProbData): System.UInt16

---@class app.user_data.EmParamRandomSize.cEnemyTableData : via.clr.ManagedObject
---@field _SizeTable System.Array<app.user_data.EmParamRandomSize.cSizeTableData>
---@field get_LegendaryId fun(self: app.user_data.EmParamRandomSize.cEnemyTableData): app.EnemyDef.LEGENDARY_ID
---@field get_EmIdFixed fun(self: app.user_data.EmParamRandomSize.cEnemyTableData): app.EnemyDef.ID_Fixed

---@class app.user_data.EmParamRandomSize.cSizeTableData : via.clr.ManagedObject
---@field get_RewardRank_L fun(self: app.user_data.EmParamRandomSize.cSizeTableData): app.QuestDef.EM_REWARD_RANK_Fixed
---@field get_RewardRank_U fun(self: app.user_data.EmParamRandomSize.cSizeTableData): app.QuestDef.EM_REWARD_RANK_Fixed
---@field getSizeTableId fun(self: app.user_data.EmParamRandomSize.cSizeTableData, id: System.Int32): app.cEmParamGuid_RandomSize_RandomSizeTbl

---@class app.cEmParamGuidBase : via.clr.ManagedObject
---@field Value System.Guid

---@class app.user_data.EmParamSize : via.UserData
---@field getSizeData fun(self: app.user_data.EmParamSize, em_id: app.EnemyDef.ID): app.user_data.EmParamSize.cSizeData

---@class app.user_data.EmParamSize.cSizeData : via.clr.ManagedObject
---@field get_CrownSize_Small fun(self: app.user_data.EmParamSize.cSizeData): System.UInt16
---@field get_CrownSize_Big fun(self: app.user_data.EmParamSize.cSizeData): System.UInt16
---@field get_CrownSize_King fun(self: app.user_data.EmParamSize.cSizeData): System.UInt16

---@class app.user_data.EmParamDifficulty2
---@field getDifficultyRate fun(self: app.user_data.EmParamDifficulty2, guid: System.Guid): app.user_data.EmParamDifficulty2.cDifficultyRate

---@class app.user_data.EmParamDifficulty2.cDifficultyRate : via.clr.ManagedObject
---@field get_RewardGrade fun(self: app.user_data.EmParamDifficulty2.cDifficultyRate): System.Int32
---@field get_RewardRank fun(self: app.user_data.EmParamDifficulty2.cDifficultyRate): app.QuestDef.EM_REWARD_RANK_Fixed

---@class app.cEnemyContextHolder : app.cGameContextHolder
---@field get_Em fun(self: app.cEnemyContextHolder): app.cEnemyContext

---@class app.cEnemyContext : app.cGameContext
---@field Area app.cEmModuleArea

---@class app.cEmModuleArea : app.cEmModuleBase
---@field get_CurrentAreaNo fun(self: app.cEmModuleArea): System.Int32
---@field get_IsTargetArrival fun(self: app.cEmModuleArea): System.Boolean

---@class app.cContextCreateArg_Enemy : app.cContextCreateArg
---@field set_AreaNo fun(self: app.cContextCreateArg_Enemy, area: System.Int32)
