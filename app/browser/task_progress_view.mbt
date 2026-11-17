///|
fn progress_dialog(
  batch : ProgressBatch,
  jobs : TaskState,
  emit : Emit[Msg],
) -> Html {
  let needs_attention = batch.error is Some(_) ||
    batch.items.any(item => {
      item.state is (Rejected(_) | Tracking(_, Some(Failed(_))))
    })
  let active = batch.error is None &&
    batch.items.any(item => item.state.is_active())
  let interrupted = batch.error is None &&
    !jobs.sync_error.is_empty() &&
    batch.items.any(item => {
      item.state is Tracking(_, _) && item.state.is_active()
    })
  let title = match batch.error {
    Some(Rejected(_)) => "Submission rejected"
    Some(Unconfirmed(_)) => "Submission not confirmed"
    None =>
      if !active {
        "Finished"
      } else if interrupted {
        "Reconnecting…"
      } else {
        "In progress"
      }
  }
  let rows = batch.items.map(item => {
    let description = item.operation.description()
    @rui.item(
      variant=ItemDefault,
      attrs=@html.Attrs::build().role("listitem"),
      [
        @rui.item_content(@rui.item_title(description)),
        ..if batch.error is None {
          [
            @rui.item_footer(
              progress_state_view(item.state, description, interrupted~),
            ),
          ]
        },
      ],
    )
  })
  modal(
    title,
    emit,
    size=Wide(tall=false),
    [
      ..if interrupted {
        [task_error_view(title, jobs.sync_error)]
      } else {
        []
      },
      ..batch.error.map_or([], error => {
        let title = match error {
          Rejected(_) => "Submission rejected"
          _ => "Submission not confirmed"
        }
        [task_error_view(title, error.submission_message())]
      }),
      @rui.scroll_area(@rui.item_group(rows)),
      dialog_close_footer_view(
        label=if needs_attention { "Close" } else { "Hide" },
      ),
    ],
  )
}

///|
fn progress_state_view(
  state : ProgressState,
  description : String,
  interrupted~ : Bool,
) -> Html {
  if interrupted && state is Tracking(_, _) && state.is_active() {
    return badge(
      variant=Secondary,
      attrs=@html.Attrs::build().role("status"),
      "Reconnecting…",
    )
  }
  match state {
    Rejected(error) => task_error_view("Submission rejected", error.message)
    Tracking(_, Some(status)) => task_status_view(status, description)
    Submitting => @rui.spinner(label="Submitting…")
    Tracking(_, None) => @rui.spinner(label="Waiting for task status…")
  }
}
