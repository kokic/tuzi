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
  type EntryAppearance,
  type FileOperation,
  type GitOperation,
  type Task,
  type TaskKind,
  type TaskStatus,
}

///|
using @tuzi {preview_content_type, directory_contains}

///|
using @presentation {
  type SortMode,
  format_file_size,
  format_timestamp,
  default_archive_name,
  format_entry_meta,
  entry_size_view,
  entry_time_view,
  row_style,
  entry_open_area_style,
  entry_title_style,
  entry_details_style,
  panes_style,
  pane_style,
  pane_header_style,
  pane_list_style,
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
  let dialog = dialog_view(model, emit).view2(global_command_view(emit), (
    dialog,
    command,
  ) => @html.fragment([dialog, command]))
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
        Ok(config) => BaseLoaded(config)
        Err(error) => BaseFailed(error.message())
      },
    )
  })
}

///|
fn Model::apply_server_config(
  model : Model,
  config : @tuzi.ServerConfig,
) -> (Model, Cmd) {
  let location = load_browser_location(config.base, config.startup)
  let left = Path(location.left)
  let right = Path(location.right)
  let updated = {
    ..model,
    startup: Started,
    theme: config.theme,
    entry_appearance: config.entry_appearance,
    openers: Some(config.openers),
    supports_drive_selection: config.supports_drive_selection,
    active: if location.active == 0 {
      Left
    } else {
      Right
    },
    panes: (model.panes.0.navigate(left), model.panes.1.navigate(right)),
  }
  (updated, updated.save_browser_location())
}
