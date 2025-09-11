---@meta

---@class via.Object : REManagedObject
---@class via.clr.ManagedObject : via.Object
---@class via.Component : via.clr.ManagedObject
---@class via.UserData : via.clr.ManagedObject
---@class via.Scene : via.clr.ManagedObject
---@class via.Behavior : via.Component
---@class via.gui.TransformObject : via.gui.PlayObject
---@class via.gui.PlayObject : via.clr.ManagedObject

---@class via.Size
---@field w System.Single
---@field h System.Single
---@
---@class via.GameObject : via.clr.ManagedObject
---@field destroy fun(self: via.GameObject, object: via.GameObject)

---@class via.Scene : via.clr.ManagedObject
---@field get_FrameCount fun(self: via.Scene): System.UInt32

---@class via.SceneView : via.gui.TransformObject
---@field get_WindowSize fun(self: via.SceneView): via.Size

---@class via.SceneManager : NativeSingleton
---@field get_MainView fun(self: via.SceneManager): via.SceneView
---@field get_CurrentScene fun(self: via.SceneManager): via.Scene

---@class via.Application : NativeSingleton
---@field get_DeltaTime fun(self: via.Application): System.Single
