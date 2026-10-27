///|
fn session_conversation_entries(
  entries : Array[@session.Entry],
) -> Array[@session.Entry] {
  let visible : Array[@session.Entry] = []
  let mut branch_start = false
  for entry in entries {
    branch_start = branch_start || entry.branch_start
    guard entry.event is Message(message) && message.role is (User | Assistant) else {
      continue
    }
    let blocks = message.blocks.filter(block => {
      match block {
        Text(text) => !text.trim().is_empty()
        Image(..) => true
        Thinking(_) | ToolCall(..) | Unknown(_) => false
      }
    })
    guard !blocks.is_empty() ||
      message.is_error ||
      message.error is Some(_) ||
      message.stop_reason == Some("aborted") else {
      continue
    }
    visible.push({
      ..entry,
      branch_start,
      event: Message({ ..message, blocks, }),
    })
    branch_start = false
  }
  visible
}

///|
fn session_entry_view(entry : @session.Entry) -> Html {
  guard entry.event is Message(message) else { return @html.nothing }
  let is_user = message.role is User
  @html.fragment(
    [
      ..if entry.branch_start {
        [
          @rui.alert([
            @rui.alert_title("Branch change"),
            @rui.alert_description(
              "The conversation continues on a different branch.",
            ),
          ]),
        ]
      },
      div(
        style=[
          "min-width: 0",
          "display: flex",
          "flex-direction: column",
          "gap: 10px",
          ..if is_user {
            [
              "padding: 12px", "background: var(--rui-muted)", "border-radius: 8px",
            ]
          },
        ],
        [
          div(
            style=[
              "display: flex", "align-items: baseline", "gap: 8px", "flex-wrap: wrap",
            ],
            [
              span(
                style=["font-size: 0.8125rem", "font-weight: 600"],
                if is_user {
                  "User"
                } else {
                  "Assistant"
                },
              ),
              ..if message.is_error {
                [badge(variant=Destructive, "Error")]
              },
              ..if entry.timestamp is Some(timestamp) {
                [
                  @html.time(
                    datetime=timestamp,
                    style=[
                      "font-size: 0.75rem", "color: var(--rui-muted-foreground)",
                    ],
                    timestamp,
                  ),
                ]
              },
            ],
          ),
          ..message.blocks.map(session_message_block_view),
          ..if message.stop_reason == Some("aborted") {
            [badge(variant=Outline, "Interrupted")]
          },
          ..if message.error is Some(error) {
            [
              @rui.alert(variant=Destructive, [
                @rui.alert_title("Agent error"),
                @rui.alert_description(error),
              ]),
            ]
          },
        ],
      ),
    ],
  )
}

///|
fn session_message_block_view(block : @session.Block) -> Html {
  match block {
    Text(text) =>
      @markdown.markdown(text, escape_link=true, heading_anchors=false)
    Image(mime_type~, data~) =>
      match mime_type {
        "image/png" | "image/jpeg" | "image/gif" | "image/webp" =>
          @html.img(
            src="data:\{mime_type};base64,\{data}",
            alt="Message attachment (\{mime_type})",
            loading="lazy",
            style=[
              "max-width: 100%", "max-height: 28rem", "object-fit: contain", "align-self: flex-start",
            ],
          )
        _ => p("Image format not previewed: \{mime_type}.")
      }
    Thinking(_) | ToolCall(..) | Unknown(_) => @html.nothing
  }
}
