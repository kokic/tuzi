///|
/// Keep the directory marker visible when the filename is truncated.
#warnings("-alert_xss_vulnerable")
fn entry_name_view(entry : Entry, color : String) -> Html {
  span(
    style=entry_title_style(entry, color),
    title=if entry.is_dir { entry.name + "/" } else { entry.name },
    [
      span(
        style=["min-width: 0", "overflow: hidden", "text-overflow: ellipsis"],
        entry.name,
      ),
      ..if entry.is_dir {
        [span(style=["flex: none"], "/")]
      } else {
        []
      },
      ..if entry.is_symlink {
        [
          span(
            style=[
              "display: inline-flex", "flex: none", "align-self: center",
              "width: 1em", "height: 1em", "margin-left: 4px",
            ],
            title="Symbolic link",
            attrs=@html.Attrs::build().inner_html(SvgSymbolicLink),
            @html.nothing,
          ),
        ]
      },
    ],
  )
}

const SvgSymbolicLink : String = #|<svg xmlns="http://www.w3.org/2000/svg" width="1em" height="1em" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-file-symlink preview-icon"><path d="M4 11V4a2 2 0 0 1 2-2h8a2.4 2.4 0 0 1 1.706.706l3.588 3.588A2.4 2.4 0 0 1 20 8v12a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2v-3a2 2 0 0 1 2-2h7"/><path d="M14 2v5a1 1 0 0 0 1 1h5"/><path d="m10 18 3-3-3-3"/></svg>
