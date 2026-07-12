// End-to-End Simulation Pipeline for Image Processing
// This module provides execution pipelines that integrate all parts of the library:
// resizing, filtering, edge detection, Hough transforms, color quantization, and exporting.

///|
pub struct SimulationResult {
  pub original_width : Int
  pub original_height : Int
  pub block_size : Int
  pub grid_width : Int
  pub grid_height : Int
  pub palette : Array[Int]
  pub csv_data : String
  pub svg_data : String
  pub html_report : String
  pub lines_detected : Array[HoughLine]
  pub circles_detected : Array[HoughCircle]
}

///|
pub fn run_pixelate_simulation_pipeline(
  rgba : Bytes,
  w : Int,
  h : Int,
  block_size : Int,
  quantizer_type : String, // "median_cut" | "kmeans" | "octree"
  target_colors_count : Int,
  apply_dither : Bool,
  dither_type : String, // "floyd_steinberg" | "atkinson" | "stucki" | "burkes" | "ordered"
  apply_sobel : Bool,
  hough_thresh : Int,
  max_hough_lines : Int,
) -> SimulationResult {

  // 1. Image Resizing (Downscale to target grid size)
  let grid_w = if w / block_size < 1 { 1 } else { w / block_size }
  let grid_h = if h / block_size < 1 { 1 } else { h / block_size }

  let downscaled_bytes = nearest_neighbor_resize(rgba, w, h, grid_w, grid_h)

  // 2. Optional Sobel edge detection & Hough line analysis
  let mut detected_lines = []
  if apply_sobel {
    detected_lines = hough_lines(
      downscaled_bytes, grid_w, grid_h, hough_thresh, max_hough_lines,
    )
  }

  // 3. Extract colors for quantization
  let extracted_colors = []
  for i = 0; i < grid_w * grid_h; i = i + 1 {
    let idx = i * 4
    let r = downscaled_bytes[idx].to_int()
    let g = downscaled_bytes[idx + 1].to_int()
    let b = downscaled_bytes[idx + 2].to_int()
    extracted_colors.push((r << 16) | (g << 8) | b)
  }

  // 4. Run Quantization
  let palette = if quantizer_type == "kmeans" {
    kmeans_quantize(extracted_colors, target_colors_count, 10)
  } else if quantizer_type == "octree" {
    octree_quantize(extracted_colors, target_colors_count)
  } else {
    // default to median cut
    build_palette(extracted_colors)
  }

  // 5. Apply Dithering or Clamping
  let dithered_bytes = if apply_dither {
    if dither_type == "atkinson" {
      dither_atkinson(downscaled_bytes, grid_w, grid_h, palette)
    } else if dither_type == "stucki" {
      dither_stucki(downscaled_bytes, grid_w, grid_h, palette)
    } else if dither_type == "burkes" {
      dither_burkes(downscaled_bytes, grid_w, grid_h, palette)
    } else if dither_type == "ordered" {
      dither_ordered_bayer(downscaled_bytes, grid_w, grid_h, palette, 4)
    } else {
      dither_floyd_steinberg(downscaled_bytes, grid_w, grid_h, palette)
    }
  } else {
    // Clamping nearest color without dithering
    let res_arr = Array::make(grid_w * grid_h * 4, (0).to_byte())
    for i = 0; i < grid_w * grid_h; i = i + 1 {
      let idx = i * 4
      let r = downscaled_bytes[idx].to_int().to_double()
      let g = downscaled_bytes[idx + 1].to_int().to_double()
      let b = downscaled_bytes[idx + 2].to_int().to_double()
      let closest = find_closest_palette_color(r, g, b, palette)
      res_arr[idx] = ((closest >> 16) & 0xFF).to_byte()
      res_arr[idx + 1] = ((closest >> 8) & 0xFF).to_byte()
      res_arr[idx + 2] = (closest & 0xFF).to_byte()
      res_arr[idx + 3] = downscaled_bytes[idx + 3]
    }
    make_bytes(grid_w * grid_h * 4, fn(j) { res_arr[j] })
  }

  // 6. Convert dithered image back to integer grid for exporting
  let final_grid = Array::make(grid_w * grid_h, 0)
  for i = 0; i < grid_w * grid_h; i = i + 1 {
    let idx = i * 4
    let r = dithered_bytes[idx].to_int()
    let g = dithered_bytes[idx + 1].to_int()
    let b = dithered_bytes[idx + 2].to_int()
    final_grid[i] = (r << 16) | (g << 8) | b
  }

  // 7. Generate Exports
  let csv = export_csv(final_grid, grid_w, grid_h)
  let svg = export_svg(final_grid, grid_w, grid_h, 15)
  let html = export_html_report(final_grid, grid_w, grid_h)

  {
    original_width: w,
    original_height: h,
    block_size,
    grid_width: grid_w,
    grid_height: grid_h,
    palette,
    csv_data: csv,
    svg_data: svg,
    html_report: html,
    lines_detected: detected_lines,
    circles_detected: [],
  }
}

// Triggers pipeline running on random inputs to check for general crashes under stress

///|
pub fn run_stress_simulation(cycles : Int) -> Bool {
  let rng = make_random(98765L)
  for cycle = 0; cycle < cycles; cycle = cycle + 1 {
    let w = rng.next_int(16, 64)
    let h = rng.next_int(16, 64)
    let block = rng.next_int(2, 8)
    let rgba = rng.generate_random_rgba(w * h)

    let quant_types = ["median_cut", "kmeans", "octree"]
    let quant = quant_types[rng.next_int(0, 2)]

    let dith_types = [
      "floyd_steinberg", "atkinson", "stucki", "burkes", "ordered",
    ]
    let dith = dith_types[rng.next_int(0, 4)]

    let res = run_pixelate_simulation_pipeline(
      rgba, w, h, block, quant, 8, true, dith, true, 100, 5,
    )

    if res.grid_width <= 0 || res.grid_height <= 0 {
      return false
    }
  }
  true
}
