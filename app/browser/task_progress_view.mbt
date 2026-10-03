///|
fn progress_dialog(batch : ProgressBatch, emit : Emit[Msg]) -> Html {
  let needs_attention = batch.error is Some(_) ||
    batch.items.any(item => {
      item.state is (Rejected(_) | Tracking(_, Some(Failed(_))))
    })
  let rows = batch.items.map(item => {
    let description = item.operation.description()
    div(
      style=[
        "display: grid", "gap: 10px", "padding: 14px", "border: 1px solid var(--rui-border)",
        "border-radius: var(--rui-radius)", "min-width: 0",
      ],
      [
        ..if batch.error is None {
          [progress_state_view(item.state, description)]
        },
        p(
          style=[
            "margin: 0", "font-weight: 600", "line-height: 1.5", "overflow-wrap: anywhere",
          ],
          description,
        ),
      ],
    )
  })
  modal(
    "In progress",
    emit,
    style=["width: min(520px, 100%)"],
    [
      ..batch.error.map_or([], error => {
        let title = match error {
          Rejected(_) => "Submission rejected"
          _ => "Submission not confirmed"
        }
        [task_error_view(title, error.submission_message())]
      }),
      div(
        style=[
          "display: grid", "gap: 12px", "min-height: 0", "max-height: 60vh", "overflow-y: auto",
          "align-content: start",
        ],
        rows,
      ),
      dialog_close_footer_view(
        label=if needs_attention { "Close" } else { "Hide" },
      ),
    ],
  )
}

///|
fn progress_state_view(state : ProgressState, description : String) -> Html {
  let message = match state {
    Rejected(error) =>
      return task_error_view("Submission rejected", error.message)
    Tracking(_, Some(status)) => return task_status_view(status, description)
    Submitting => "Submitting…"
    Tracking(_, None) => "Waiting for task status…"
  }
  @rui.field_description(style=["margin: 0", "line-height: 1.5"], message)
}
