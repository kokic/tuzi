///|
priv enum NewEntryKind {
  File
  Folder
}

///|
priv enum Dialog {
  None
  Help
  Activity
  TaskDetails(Int)
  Info(InfoContext)
  Markdown(MarkdownContext)
  GitInfo(GitContext)
  DeleteConfirm(directory~ : Path, names~ : Array[String])
  RenameInput(directory~ : Path, original~ : String, input~ : String)
  ZipInput(
    directory~ : Path,
    names~ : Array[String],
    input~ : String,
    level~ : Int
  )
  UnzipInput(source~ : Path, input~ : String)
  NewEntryInput(directory~ : Path, input~ : String)
  GitRenameInput(context~ : GitContext, reference~ : String, input~ : String)
  Progress(ProgressBatch)
} derive(Eq)
