import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

const indent = "  "

pub type Direction {
  LeftToRight
  RightToLeft
  BottomToTop
  TopDown
  TopToBottom
}

pub type TextStyle {
  TextStyleUnicode
  TextStyleMarkdown
}

pub type NodeShape {
  NodeShapeDefault
  NodeShapeRound
  NodeShapeStadium
  NodeShapeSubroutine
  NodeShapeCylindrical
  NodeShapeCircle
  NodeShapeAsymmetric
}

pub type LinkStyle {
  LinkStyleArrowHead
  LinkStyleOpen
}

pub type LinkStyleVariant {
  LinkStyleVariantDotted
  LinkStyleVariantThick
}

pub type LinkTextStyle {
  LinkTextStyleCode
}

pub type Node {
  Node(to_string: fn() -> String)
}

pub type Text {
  Text(to_string: fn() -> String)
}

pub type LinkText {
  LinkText(with_link_style: fn(LinkStyle, Option(LinkStyleVariant)) -> String)
}

pub opaque type FlowChart {
  FlowChart(title: Option(String), direction: Direction, body: List(Node))
}

pub fn new(title: Option(String), direction: Direction) -> FlowChart {
  FlowChart(title, direction, body: [])
}

pub fn add_node(fc: FlowChart, node: Node) -> FlowChart {
  FlowChart(..fc, body: list.append(fc.body, [node]))
}

pub fn string(fc: FlowChart) -> Result(String, String) {
  let direction_node = build_direction_node(fc.direction)

  let title_node = case fc.title {
    Some(t) -> build_title_node(t)
    _ -> empty_node()
  }

  let nodes = list.append([title_node, direction_node], fc.body)

  Ok(
    "```mermaid"
    |> join_nodes(nodes)
    |> string.append("```"),
  )
}

pub fn text(raw: String, text_style: Option(TextStyle)) -> Text {
  Text(fn() {
    case text_style {
      Some(style) -> {
        case style {
          TextStyleUnicode -> "\"" <> raw <> "\""
          TextStyleMarkdown -> "\"`" <> raw <> "`\""
        }
      }
      _ -> raw
    }
  })
}

fn get_node_shape_symbols(node_shape: NodeShape) -> #(String, String) {
  case node_shape {
    NodeShapeRound -> #("(", ")")
    NodeShapeStadium -> #("([", "])")
    NodeShapeSubroutine -> #("[[", "]]")
    NodeShapeCylindrical -> #("[(", ")]")
    NodeShapeCircle -> #("((", "))")
    NodeShapeAsymmetric -> #(">", "]")
    NodeShapeDefault -> #("[", "]")
  }
}

pub fn node(
  name name: String,
  node_shape node_shape: NodeShape,
  text text: Option(Text),
) -> Node {
  let #(open, close) = get_node_shape_symbols(node_shape)

  Node(fn() {
    indent
    <> case text {
      Some(t) -> name <> open <> t.to_string() <> close
      _ -> name
    }
  })
}

pub fn multi_line_node(
  name name: String,
  lines texts: List(String),
  node_shape node_shape: NodeShape,
  text_style text_style: Option(TextStyle),
) -> Node {
  let #(open, close) = case text_style {
    Some(TextStyleUnicode) -> #("[\"", "\"]")
    Some(TextStyleMarkdown) -> #("[\"`", "`\"]")
    _ -> #("[", "]")
  }

  let texts_as_nodes =
    texts
    |> list.map(fn(name) { node(name, node_shape, None) })

  Node(fn() {
    indent
    <> case texts {
      [] -> name
      _ ->
        name
        <> open
        |> join_nodes(texts_as_nodes)
        |> string.append(close)
    }
  })
}

fn get_link_style_symbol(
  link_style: LinkStyle,
  variant: Option(LinkStyleVariant),
) -> String {
  case link_style, variant {
    LinkStyleOpen, Some(LinkStyleVariantDotted) -> "-.-"
    LinkStyleOpen, Some(LinkStyleVariantThick) -> "==="
    LinkStyleArrowHead, Some(LinkStyleVariantDotted) -> "-.->"
    LinkStyleArrowHead, Some(LinkStyleVariantThick) -> "==>"
    LinkStyleOpen, _ -> "---"
    LinkStyleArrowHead, _ -> "-->"
  }
}

pub fn link(
  from from: String,
  to to: String,
  link_style link_style: LinkStyle,
  link_text link_text: Option(LinkText),
  link_style_variant link_style_variant: Option(LinkStyleVariant),
) -> Node {
  let link_symbol_and_text = case link_text {
    Some(text) -> text.with_link_style(link_style, link_style_variant)
    _ -> get_link_style_symbol(link_style, link_style_variant)
  }

  Node(fn() { indent <> from <> " " <> link_symbol_and_text <> " " <> to })
}

pub fn chain(links: List(Node)) -> Node {
  let initial = result.unwrap(list.first(links), empty_node())

  Node(fn() {
    links
    |> list.fold(string.trim(initial.to_string()), fn(acc, curr) {
      let curr_string = string.trim(curr.to_string())

      case string.first(curr_string), string.last(acc) {
        Ok(first), Ok(last) if first == last ->
          string.replace(acc, last, curr_string)
        _, _ -> acc
      }
    })
  })
}

pub fn link_text(
  text text: String,
  link_text_style link_text_style: Option(LinkTextStyle),
) -> LinkText {
  LinkText(
    fn(link_style: LinkStyle, link_style_variant: Option(LinkStyleVariant)) {
      let #(open, close) = case
        link_style,
        link_style_variant,
        link_text_style
      {
        LinkStyleArrowHead,
          Some(LinkStyleVariantDotted),
          Some(LinkTextStyleCode)
        -> #("-.->|", "|")
        LinkStyleArrowHead, Some(LinkStyleVariantThick), Some(LinkTextStyleCode) -> #(
          "==>|",
          "|",
        )
        LinkStyleArrowHead, Some(LinkStyleVariantThick), _ -> #("==", "==>")
        LinkStyleArrowHead, Some(LinkStyleVariantDotted), _ -> #("-.", ".->")
        LinkStyleArrowHead, _, Some(LinkTextStyleCode) -> #("-->|", "|")
        LinkStyleOpen, Some(LinkStyleVariantDotted), Some(LinkTextStyleCode) -> #(
          "-.-|",
          "|",
        )
        LinkStyleOpen, Some(LinkStyleVariantThick), Some(LinkTextStyleCode) -> #(
          "===|",
          "|",
        )
        LinkStyleOpen, _, Some(LinkTextStyleCode) -> #("---|", "|")
        LinkStyleOpen, Some(LinkStyleVariantDotted), _ -> #("-.", ".-")
        LinkStyleOpen, Some(LinkStyleVariantThick), _ -> #("==", "===")

        LinkStyleArrowHead, _, _ -> #("--", "-->")
        LinkStyleOpen, _, _ -> #("--", "---")
      }

      open <> text <> close
    },
  )
}

fn join_nodes(text: String, nodes: List(Node)) -> String {
  case nodes {
    [] -> text <> "\n"
    [node, ..rest] ->
      text
      <> "\n"
      |> string.append(join_nodes(node.to_string(), rest))
  }
}

fn build_title_node(text: String) -> Node {
  Node(fn() { "---\ntitle: " <> text <> "\n---" })
}

fn empty_node() -> Node {
  Node(fn() { "" })
}

fn build_direction_node(direction: Direction) -> Node {
  Node(fn() {
    "flowchart "
    <> case direction {
      LeftToRight -> "LR"
      RightToLeft -> "RL"
      TopDown -> "TD"
      BottomToTop -> "BT"
      TopToBottom -> "TB"
    }
  })
}
