///|
fn SortMode::label(self : SortMode) -> String {
  match self {
    Name => "name"
    Size => "size"
    Time => "time"
  }
}

///|
fn pane_sort_select(
  id : String,
  idx : PaneSide,
  sort : SortMode,
  emit : Emit[Msg],
) -> Val[Html] {
  let modes : Array[SortMode] = [Name, Size, Time]
  @rui.select(
    id~,
    options=modes.map(mode => {
      @rui.select_option(value=mode.label(), label=mode.label())
    }),
    default_value=sort.label(),
    align=End,
    on_value_change=emit.map(value => {
      let sort : SortMode = match value {
        "size" => Size
        "time" => Time
        _ => Name
      }
      SortChanged(idx, sort)
    }),
    class="pane-sort",
    style=[
      UI_FONT_STYLE,
      "display: inline-grid",
      "grid-template-columns: max-content",
      "width: max-content",
      "flex: none",
      "margin-inline-end: 4px",
      "font-size: 0.75rem",
      "font-weight: 500",
      "line-height: 1rem",
      "--tuzi-sort-padding: 0.5rem",
      "--tuzi-sort-gap: 0.25rem",
    ],
    render=scope => {
      fragment([
        // Overlap every label in one grid cell to reserve the widest text.
        // Include the trigger's padding, border, gap, and one-rem chevron.
        span(
          attrs=@html.Attrs::build().aria_hidden("true"),
          style=[
            "grid-area: 1 / 1", "display: flex", "align-items: center", "gap: var(--tuzi-sort-gap)",
            "padding: 0 var(--tuzi-sort-padding)", "border: 1px solid transparent",
            "visibility: hidden", "pointer-events: none",
          ],
          [
            span(
              style=["display: grid"],
              modes.map(mode => span(style=["grid-area: 1 / 1"], mode.label())),
            ),
            span(style=["width: 1rem", "flex: none"], ""),
          ],
        ),
        @rui.select_trigger(
          scope~,
          aria_label="Sort files",
          title="Sort files (s)",
          style=[
            "grid-area: 1 / 1", "height: 1.5rem", "padding: 0 var(--tuzi-sort-padding)",
            "gap: var(--tuzi-sort-gap)", "font: inherit",
          ],
        ),
        @rui.select_content(
          scope~,
          attrs=@html.Attrs::build().aria_label("Sort files"),
          style=[UI_FONT_STYLE],
          modes.map(mode => {
            @rui.select_item(
              scope~,
              value=mode.label(),
              style=[UI_FONT_STYLE],
              mode.label(),
            )
          }),
        ),
      ])
    },
  )
}
