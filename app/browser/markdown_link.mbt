///|
priv struct MarkdownLink {
  path : Path
  query : String
  fragment : String?
}

///|
fn MarkdownContext::local_link(
  context : MarkdownContext,
  destination : String,
) -> MarkdownLink? {
  guard !destination.is_empty() && !destination.has_prefix("//") else {
    return None
  }
  let (reference, fragment) = destination
    .split_once("#")
    .map_or((destination[:], None), pair => (pair.0, Some(pair.1.to_owned())))
  let (path, query) = reference
    .split_once("?")
    .map_or((reference, ""), pair => (pair.0, "&\{pair.1}"))
  let first_segment = path.split_once("/").map_or(path, pair => pair.0)
  guard !first_segment.contains(":") else { return None }
  let decoded = @percent.decode(path) catch { _ => return None }
  let target = if path.is_empty() {
    context.path
  } else if path.has_prefix("/") {
    Path(decoded)
  } else {
    context.path.dirname().resolve(Path("./\{decoded}")) catch {
      _ => return None
    }
  }
  Some({ path: target, query, fragment, })
}

///|
fn MarkdownContext::resolve_link(
  context : MarkdownContext,
  destination : String,
) -> String {
  guard !destination.has_prefix("#") else { return destination }
  guard context.local_link(destination) is Some(link) else {
    return destination
  }
  link.path.file_url() +
  link.query +
  link.fragment.map_or("", fragment => "#" + fragment)
}

///|
fn MarkdownContext::link_attributes(
  context : MarkdownContext,
  destination : String,
  emit : Emit[Msg],
) -> @html.Attrs {
  let attributes = @html.Attrs::build()
  guard context.local_link(destination) is Some(link) else { return attributes }
  attributes.on_click(event => {
    guard event.get_button() == 0 &&
      !event.get_ctrl_key() &&
      !event.get_meta_key() &&
      !event.get_shift_key() &&
      !event.get_alt_key() &&
      !event.get_default_prevented() else {
      return @rabbita.none
    }
    event.prevent_default()
    emit(MarkdownEvent(LinkClicked(context.id, link)))
  })
}

///|
fn MarkdownContext::scroll_to_fragment(context : MarkdownContext) -> Cmd {
  guard context.view == Preview &&
    context.content is Loaded(Ok(_)) &&
    context.fragment is Some(fragment) else {
    return @rabbita.none
  }
  let fragment = @percent.decode(fragment) catch { _ => return @rabbita.none }
  @cmd.custom_cmd(kind=AfterRender, _ => {
    guard @dom.document()
      .get_element_by_id("markdown-document-\{context.id}")
      .to_option()
      is Some(root) else {
      return
    }
    if fragment.is_empty() {
      root.scroll_into_view_with_options(block="start", container="nearest")
      return
    }
    for element in root.query_selector_all("[id]").iter() {
      if element.get_attribute("id") == Some(fragment) {
        element.scroll_into_view_with_options(
          block="start",
          container="nearest",
        )
        return
      }
    }
  })
}
