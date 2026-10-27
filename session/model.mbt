///|
pub(all) enum Agent {
  Pi
} derive(Eq)

///|
pub(all) enum Role {
  User
  Assistant
  System
  Tool
  Custom(String)
} derive(Eq)

///|
pub(all) enum Block {
  Text(String)
  Thinking(String)
  ToolCall(id~ : String, name~ : String, arguments~ : Json)
  Image(mime_type~ : String, data~ : String)
  Unknown(Json)
} derive(Eq)

///|
pub(all) struct Message {
  role : Role
  blocks : Array[Block]
  provider : String?
  model : String?
  tool_call_id : String?
  tool_name : String?
  is_error : Bool
  stop_reason : String?
  error : String?
} derive(Eq)

///|
pub(all) enum Event {
  Message(Message)
  Notice(title~ : String, blocks~ : Array[Block])
  Unknown(String)
} derive(Eq)

///|
pub(all) struct Entry {
  line : Int32
  id : String
  parent_id : String?
  timestamp : String?
  branch_start : Bool
  event : Event
  raw : Json
} derive(Eq)

///|
pub(all) struct Diagnostic {
  line : Int32
  message : String
  source : String
} derive(Eq)

///|
pub(all) struct Document {
  agent : Agent
  id : String
  version : Int32
  cwd : String?
  timestamp : String?
  header : Json
  entries : Array[Entry]
  diagnostics : Array[Diagnostic]
} derive(Eq)

///|
pub extend Agent with Eq::{equal, not_equal}

///|
pub extend Role with Eq::{equal, not_equal}

///|
pub extend Block with Eq::{equal, not_equal}

///|
pub extend Message with Eq::{equal, not_equal}

///|
pub extend Event with Eq::{equal, not_equal}

///|
pub extend Entry with Eq::{equal, not_equal}

///|
pub extend Diagnostic with Eq::{equal, not_equal}

///|
pub extend Document with Eq::{equal, not_equal}
