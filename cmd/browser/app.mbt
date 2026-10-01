///|
using @rabbita {type Cmd, type Emit, type Html, type Val}

///|
using @html {div, form, fragment, input, li, p, span, ul}

///|
using @path {type Path}

///|
using @tuzi {
  type Entry,
  type Theme,
  type IconMode,
  type IconTheme,
  type SortMode,
  type FileOperation,
  type GitOperation,
  type Task,
  type TaskKind,
  type TaskStatus,
}

///|
using @tuzi {
  format_file_size,
  format_timestamp,
  default_archive_name,
  preview_content_type,
}

///|
type ToastSender = (String, String?, @rui.ToastVariant) -> Cmd

///|
fn create_file_browser() -> Val[Html] {
  let toast_send : Ref[ToastSender?] = Ref(None)
  let (model, emit) = @rabbita.create_state_with_init(
    init=emit => {
      (
        Model::initialize(),
        @rabbita.batch([request_startup(emit), task_socket_cmd(0, emit)]),
      )
    },
    update=(model, msg, emit) => {
      let (next, command) = Model::update(model, msg, emit, toast_send)
      // The browser owns the native dialog's open state: open the host once
      // when the app transitions from no dialog to some dialog.
      if model.dialog is None && next.dialog != None {
        (next, @rabbita.batch([command, @dialog.show(DialogId)]))
      } else {
        (next, command)
      }
    },
    subscriptions=Model::subscriptions,
  )
  let dialog = dialog_view(model, emit)
  let panes = panes_view(model, emit)
  let toaster = @rui.sonner(max_toasts=3, position="bottom-right", scope => {
    toast_send.val = Some((title, description, variant) => {
      scope.show(title~, description?, variant~)
    })
    @html.nothing
  })
  model.view4(dialog, toaster, panes, (model, dialog, toaster, panes) => {
    model.view(emit, dialog~, toaster~, panes~)
  })
}

///|
fn request_startup(emit : Emit[Msg]) -> Cmd {
  request_api("/api/base", result => {
    emit(
      match result {
        Ok(config) => {
          let config : @tuzi.ServerConfig = config
          BaseLoaded(config.base, config.theme, config.icons)
        }
        Err(error) => BaseFailed(error.message())
      },
    )
  })
}
