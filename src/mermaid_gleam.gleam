import gleam/io
import gleam/option.{None, Some}
import gleam/result
import mermaid/flowchart.{
  LeftToRight, LinkStyleArrowHead, LinkStyleOpen, LinkStyleVariantThick,
  NodeShapeDefault, TextStyleMarkdown,
}

pub fn main() {
  let fc = flowchart.new(Some("Hello world"), LeftToRight)

  fc
  |> flowchart.add_node(flowchart.node(
    name: "markdown",
    text: Some(flowchart.text("This **is** _Markdown_", Some(TextStyleMarkdown))),
    node_shape: NodeShapeDefault,
  ))
  |> flowchart.add_node(flowchart.multi_line_node(
    name: "newLines",
    lines: ["Line 1", "Line 2", "Line 3"],
    text_style: None,
    node_shape: NodeShapeDefault,
  ))
  |> flowchart.add_node(flowchart.link(
    from: "markDown",
    to: "newLines",
    link_style: LinkStyleArrowHead,
    link_style_variant: Some(LinkStyleVariantThick),
    link_text: None,
  ))
  |> flowchart.add_node(
    flowchart.chain([
      flowchart.link(
        from: "A",
        to: "B",
        link_style: LinkStyleOpen,
        link_style_variant: None,
        link_text: None,
      ),
      flowchart.link(
        from: "B",
        to: "C",
        link_style: LinkStyleArrowHead,
        link_style_variant: None,
        link_text: None,
      ),
      flowchart.link(
        from: "C",
        to: "D",
        link_style: LinkStyleArrowHead,
        link_style_variant: None,
        link_text: None,
      ),
    ]),
  )
  |> flowchart.string
  |> result.map(io.println)
}
