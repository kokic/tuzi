///|
fn session_entry_view(entry : @session.Entry) -> Html {
  let (label, is_user, is_error) = match entry.event {
    Message(message) =>
      (
        match message.role {
          User => "User"
          Assistant => "Assistant"
          System => "System"
          Tool => message.tool_name.unwrap_or("Tool result")
          Custom(role) => role
        },
        message.role is User,
        message.is_error,
      )
    Notice(title~, ..) => (title, false, false)
    Unknown(kind) => ("Unknown event: \{kind}", false, false)
  }
  let body = match entry.event {
    Message(message) => session_message_view(message)
    Notice(blocks~, ..) => session_blocks_view(blocks, markdown=true)
    Unknown(_) => @html.nothing
  }
  @html.fragment(
    [
      ..if entry.branch_start {
        [
          @rui.alert([
            @rui.alert_title("Branch change"),
            @rui.alert_description(
              entry.parent_id.map_or("This record starts a new root.", parent => {
                "This record continues from \{parent}, not the preceding record."
              }),
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
              span(style=["font-size: 0.8125rem", "font-weight: 600"], label),
              ..if is_error {
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
              span(
                title="Entry \{entry.id}",
                style=[
                  "font-size: 0.75rem", "color: var(--rui-muted-foreground)", "margin-left: auto",
                ],
                "Line \{entry.line}",
              ),
            ],
          ),
          body,
          session_disclosure(
            "Raw record",
            session_code_view(entry.raw.stringify(indent=2)),
          ),
        ],
      ),
    ],
  )
}

///|
fn session_message_view(message : @session.Message) -> Html {
  let markdown = message.role is (User | Assistant)
  let content = session_blocks_view(message.blocks, markdown~)
  @html.fragment(
    [
      ..if message.model is Some(model) {
        [
          span(
            style=["font-size: 0.75rem", "color: var(--rui-muted-foreground)"],
            message.provider.map_or(model, provider => "\{provider} / \{model}"),
          ),
        ]
      },
      ..if message.tool_call_id is Some(id) {
        [
          span(
            style=[
              CODE_FONT_STYLE,
              "font-size: 0.75rem",
              "color: var(--rui-muted-foreground)",
            ],
            "Call \{id}",
          ),
        ]
      },
      match message.role {
        System => session_disclosure("System content", content)
        Tool => session_disclosure("Tool result", content)
        _ => content
      },
      ..if message.stop_reason is Some(reason) &&
        reason != "stop" &&
        reason != "toolUse" {
        [badge(variant=Outline, "Stopped: \{reason}")]
      },
      ..if message.error is Some(error) {
        [
          @rui.alert(variant=Destructive, [
            @rui.alert_title("Agent error"),
            @rui.alert_description(session_code_view(error)),
          ]),
        ]
      },
    ],
  )
}

///|
fn session_blocks_view(
  blocks : Array[@session.Block],
  markdown~ : Bool,
) -> Html {
  div(
    style=[
      "display: flex", "flex-direction: column", "gap: 10px", "min-width: 0",
    ],
    blocks.map(block => {
      match block {
        Text(text) =>
          if markdown {
            @markdown.markdown(text, escape_link=true, heading_anchors=false)
          } else {
            session_code_view(text)
          }
        Thinking(text) =>
          session_disclosure("Thinking", session_code_view(text))
        ToolCall(id~, name~, arguments~) =>
          session_disclosure(
            "Tool call: \{name}",
            div([
              p(
                style=[CODE_FONT_STYLE, "font-size: 0.75rem", "margin: 0 0 8px"],
                "Call \{id}",
              ),
              session_code_view(arguments.stringify(indent=2)),
            ]),
          )
        Image(mime_type~, data~) =>
          match mime_type {
            "image/png" | "image/jpeg" | "image/gif" | "image/webp" =>
              @html.img(
                src="data:\{mime_type};base64,\{data}",
                alt="Session attachment (\{mime_type})",
                loading="lazy",
                style=[
                  "max-width: 100%", "max-height: 28rem", "object-fit: contain",
                  "align-self: flex-start",
                ],
              )
            _ =>
              p(
                "Image format not previewed: \{mime_type}. See the raw record for its data.",
              )
          }
        Unknown(value) =>
          session_disclosure(
            "Unknown content",
            session_code_view(value.stringify(indent=2)),
          )
      }
    }),
  )
}

///|
fn session_code_view(source : String) -> Html {
  @html.pre(
    style=[
      CODE_FONT_STYLE,
      "margin: 0",
      "white-space: pre-wrap",
      "overflow-wrap: anywhere",
      "font-size: 0.8125rem",
      "line-height: 1.6",
      "max-height: 24rem",
      "overflow: auto",
    ],
    source,
  )
}

///|
// Native disclosures keep their own state inside message-scroller's static content.
fn session_disclosure(label : String, content : Html) -> Html {
  @html.details(
    style=[
      "min-width: 0", "border-left: 2px solid var(--rui-border)", "padding-left: 10px",
    ],
    [
      @html.summary(
        style=[
          UI_FONT_STYLE,
          "cursor: pointer",
          "font-size: 0.8125rem",
          "color: var(--rui-muted-foreground)",
          "padding-block: 4px",
        ],
        label,
      ),
      div(style=["padding-block: 8px", "min-width: 0"], content),
    ],
  )
}
