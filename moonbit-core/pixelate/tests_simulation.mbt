// Simulation Integration Tests
// This file tests the integrated simulation pipelines under different configurations.

///|
test "simulation_pipeline_basic" {
  let rng = make_random(12345L)
  let w = 32
  let h = 32
  let rgba = rng.generate_random_rgba(w * h)

  let result = run_pixelate_simulation_pipeline(
    rgba, w, h, 4, "median_cut", 8, true, "floyd_steinberg", true, 100, 5,
  )

  assert_eq(result.original_width, 32)
  assert_eq(result.original_height, 32)
  assert_eq(result.block_size, 4)
  assert_eq(result.grid_width, 8)
  assert_eq(result.grid_height, 8)
  assert_true(result.palette.length() > 0)
  assert_true(result.csv_data.length() > 0)
  assert_true(result.svg_data.length() > 0)
  assert_true(result.html_report.length() > 0)
}

///|
test "simulation_pipeline_kmeans" {
  let rng = make_random(54321L)
  let w = 24
  let h = 24
  let rgba = rng.generate_random_rgba(w * h)

  let result = run_pixelate_simulation_pipeline(
    rgba, w, h, 2, "kmeans", 4, false, "none", false, 100, 5,
  )

  assert_eq(result.grid_width, 12)
  assert_eq(result.grid_height, 12)
  assert_true(result.palette.length() > 0)
}

///|
test "simulation_pipeline_octree" {
  let rng = make_random(98765L)
  let w = 16
  let h = 16
  let rgba = rng.generate_random_rgba(w * h)

  let result = run_pixelate_simulation_pipeline(
    rgba, w, h, 2, "octree", 5, true, "atkinson", false, 100, 5,
  )

  assert_eq(result.grid_width, 8)
  assert_eq(result.grid_height, 8)
  assert_true(result.palette.length() > 0)
}

///|
test "simulation_pipeline_dither_options" {
  let rng = make_random(13579L)
  let w = 16
  let h = 16
  let rgba = rng.generate_random_rgba(w * h)

  let r1 = run_pixelate_simulation_pipeline(
    rgba, w, h, 2, "median_cut", 4, true, "stucki", false, 100, 5,
  )
  let r2 = run_pixelate_simulation_pipeline(
    rgba, w, h, 2, "median_cut", 4, true, "burkes", false, 100, 5,
  )
  let r3 = run_pixelate_simulation_pipeline(
    rgba, w, h, 2, "median_cut", 4, true, "ordered", false, 100, 5,
  )

  assert_eq(r1.grid_width, 8)
  assert_eq(r2.grid_width, 8)
  assert_eq(r3.grid_width, 8)
}

///|
test "stress_simulation_run" {
  let success = run_stress_simulation(5)
  assert_true(success)
}
