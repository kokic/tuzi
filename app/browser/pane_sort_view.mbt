///|
fn SortMode::label(self : SortMode) -> String {
  match self {
    NameAscending => "A-Z"
    NameDescending => "Z-A"
    SizeDescending => "Largest"
    SizeAscending => "Smallest"
    TimeDescending => "Latest"
    TimeAscending => "Oldest"
  }
}

///|
fn SortMode::value(self : SortMode) -> String {
  match self {
    NameAscending => "name-ascending"
    NameDescending => "name-descending"
    SizeDescending => "size-descending"
    SizeAscending => "size-ascending"
    TimeDescending => "time-descending"
    TimeAscending => "time-ascending"
  }
}

///|
fn pane_sort_select(
  id : String,
  idx : PaneSide,
  sort : SortMode,
  emit : Emit[Msg],
) -> Val[Html] {
  let modes = SortMode::all()
  @rui.select(
    id~,
    options=modes.map(mode => {
      @rui.select_option(value=mode.value(), label=mode.label())
    }),
    default_value=sort.value(),
    align=End,
    on_value_change=value => {
      guard modes.iter().find_first(mode => mode.value() == value) is Some(sort) else {
        return @rabbita.none
      }
      emit(SortChanged(idx, sort))
    },
    class="pane-sort",
    style=[
      @presentation.UI_FONT_STYLE,
      "display: inline-grid",
      "grid-template-columns: max-content",
      "width: max-content",
      "flex: none",
      "margin-inline-end: 4px",
      "font-weight: var(--tuzi-weight-ui)",
      "line-height: 1rem",
      "--tuzi-sort-padding: 0.5rem",
      "--tuzi-sort-gap: 0.25rem",
    ],
    render=scope => {
      fragment([
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
          class="tuzi-text-action",
          title="Sort files (s)",
          style=[
            "grid-area: 1 / 1", "height: 1.5rem", "padding: 0 var(--tuzi-sort-padding)",
            "gap: var(--tuzi-sort-gap)", "font: inherit", "font-weight: var(--tuzi-text-action-weight)",
            "border-color: transparent",
          ],
        ),
        @rui.select_content(
          scope~,
          attrs=@html.Attrs::build().aria_label("Sort files"),
          modes.map(mode => {
            @rui.select_item(
              scope~,
              value=mode.value(),
              style=[@presentation.UI_FONT_STYLE],
              mode.label(),
            )
          }),
        ),
      ])
    },
  )
}
