// Exporter utilities for bead patterns and statistics
// This module provides functions to format and export pixel grids and palette metrics:
// - CSV string exporter (coordinates and hex colors)
// - SVG string exporter (grid pattern drawn as circular beads)
// - HTML report exporter (interactive sheet with stats and layout)

///|
fn int_to_hex_hash(color : Int) -> String {
  let hex_chars = [
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
  ]
  let mut s = "#"
  let r = (color >> 16) & 0xFF
  let g = (color >> 8) & 0xFF
  let b = color & 0xFF
  s = s + hex_chars[r / 16] + hex_chars[r % 16]
  s = s + hex_chars[g / 16] + hex_chars[g % 16]
  s = s + hex_chars[b / 16] + hex_chars[b % 16]
  s
}

///|
pub fn export_csv(grid : Array[Int], w : Int, h : Int) -> String {
  let mut res = "X,Y,ColorHex\n"
  for y = 0; y < h; y = y + 1 {
    for x = 0; x < w; x = x + 1 {
      let idx = y * w + x
      let c = grid[idx] & 0xFFFFFF
      let hex = int_to_hex_hash(c)
      res = res + x.to_string() + "," + y.to_string() + "," + hex + "\n"
    }
  }
  res
}

///|
pub fn export_svg(
  grid : Array[Int],
  w : Int,
  h : Int,
  bead_size : Int,
) -> String {
  let radius = bead_size.to_double() / 2.0
  let width_svg = w * bead_size
  let height_svg = h * bead_size

  let mut svg = "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 " +
    width_svg.to_string() +
    " " +
    height_svg.to_string() +
    "\" width=\"" +
    width_svg.to_string() +
    "\" height=\"" +
    height_svg.to_string() +
    "\">\n"

  // Background
  svg = svg + "  <rect width=\"100%\" height=\"100%\" fill=\"#F5F5F5\" />\n"

  // Grid lines (very light)
  for y = 0; y <= h; y = y + 1 {
    let y_pos = y * bead_size
    svg = svg +
      "  <line x1=\"0\" y1=\"" +
      y_pos.to_string() +
      "\" x2=\"" +
      width_svg.to_string() +
      "\" y2=\"" +
      y_pos.to_string() +
      "\" stroke=\"#E0E0E0\" stroke-width=\"0.5\" />\n"
  }
  for x = 0; x <= w; x = x + 1 {
    let x_pos = x * bead_size
    svg = svg +
      "  <line x1=\"" +
      x_pos.to_string() +
      "\" y1=\"0\" x2=\"" +
      x_pos.to_string() +
      "\" y2=\"" +
      height_svg.to_string() +
      "\" stroke=\"#E0E0E0\" stroke-width=\"0.5\" />\n"
  }

  // Circles representing beads
  for y = 0; y < h; y = y + 1 {
    let cy = y.to_double() * bead_size.to_double() + radius
    for x = 0; x < w; x = x + 1 {
      let cx = x.to_double() * bead_size.to_double() + radius
      let idx = y * w + x
      let color = grid[idx] & 0xFFFFFF
      let hex = int_to_hex_hash(color)

      svg = svg +
        "  <circle cx=\"" +
        cx.to_string() +
        "\" cy=\"" +
        cy.to_string() +
        "\" r=\"" +
        (radius - 0.5).to_string() +
        "\" fill=\"" +
        hex +
        "\" stroke=\"#333333\" stroke-width=\"0.2\" />\n"
    }
  }

  svg = svg + "</svg>\n"
  svg
}

///|
struct ExporterStat {
  hex : String
  count : Int
}

///|
fn add_to_exporter_stats(arr : Array[ExporterStat], hex : String) -> Unit {
  for i = 0; i < arr.length(); i = i + 1 {
    if arr[i].hex == hex {
      let node = arr[i]
      arr[i] = { hex: node.hex, count: node.count + 1 }
      return
    }
  }
  arr.push({ hex, count: 1 })
}

///|
pub fn export_html_report(grid : Array[Int], w : Int, h : Int) -> String {
  let stats = []
  for i = 0; i < grid.length(); i = i + 1 {
    let hex = int_to_hex_hash(grid[i] & 0xFFFFFF)
    add_to_exporter_stats(stats, hex)
  }

  // Sort stats descending by count
  stats.sort_by(fn(a, b) { b.count - a.count })

  let mut html = "<!DOCTYPE html>\n<html>\n<head>\n" +
    "  <meta charset=\"UTF-8\">\n" +
    "  <title>Bead Pattern Report</title>\n" +
    "  <style>\n" +
    "    body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background: #fafafa; margin: 0; padding: 20px; }\n" +
    "    .container { max-width: 1000px; margin: 0 auto; background: #fff; padding: 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border-radius: 8px; }\n" +
    "    h1 { color: #333; margin-top: 0; }\n" +
    "    .stats-table { width: 100%; border-collapse: collapse; margin-top: 20px; }\n" +
    "    .stats-table th, .stats-table td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n" +
    "    .stats-table th { background-color: #f2f2f2; }\n" +
    "    .color-preview { display: inline-block; width: 24px; height: 24px; border-radius: 4px; border: 1px solid #999; vertical-align: middle; margin-right: 8px; }\n" +
    "    .grid-container { overflow-x: auto; margin-top: 30px; }\n" +
    "    .pattern-svg { display: block; max-width: 100%; height: auto; border: 1px solid #ccc; }\n" +
    "  </style>\n</head>\n<body>\n" +
    "  <div class=\"container\">\n" +
    "    <h1>Bead Pattern Instruction Sheet</h1>\n" +
    "    <p>Grid Size: " +
    w.to_string() +
    " x " +
    h.to_string() +
    " (Total " +
    (w * h).to_string() +
    " beads)</p>\n"

  // Add preview SVG
  let svg_preview = export_svg(grid, w, h, 12)
  html = html +
    "    <div class=\"grid-container\">\n" +
    svg_preview +
    "    </div>\n"

  // Add statistics table
  html = html +
    "    <h2>Bead Colors Required</h2>\n" +
    "    <table class=\"stats-table\">\n" +
    "      <thead>\n" +
    "        <tr>\n" +
    "          <th>Color Preview</th>\n" +
    "          <th>Hex Code</th>\n" +
    "          <th>Bead Count</th>\n" +
    "        </tr>\n" +
    "      </thead>\n" +
    "      <tbody>\n"

  for i = 0; i < stats.length(); i = i + 1 {
    let item = stats[i]
    html = html +
      "        <tr>\n" +
      "          <td><span class=\"color-preview\" style=\"background-color: " +
      item.hex +
      ";\"></span></td>\n" +
      "          <td>" +
      item.hex +
      "</td>\n" +
      "          <td>" +
      item.count.to_string() +
      "</td>\n" +
      "        </tr>\n"
  }

  html = html + "      </tbody>\n    </table>\n  </div>\n</body>\n</html>\n"
  html
}
