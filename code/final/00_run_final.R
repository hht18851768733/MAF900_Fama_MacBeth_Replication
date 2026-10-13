# Complete agreed Tables 1-3, from the repository root.
# Uses selected DP1-B and DP2-A calculations contained in code/final/.
# Raw caches are reused. Without raw caches, authorised WRDS access and
# internet access for the French RF download are required.
local({
  scripts <- file.path("code/final", c("00a_prepare_stock_data.R", "00b_build_table1.R",
    "00c_build_table2.R", "00e_build_table3.R"))
  if (!all(file.exists(scripts))) stop("Open the project root and ensure final steps 1-3 are installed.")
  for (path in scripts) {
    cat("\n=== Final replication:", path, "===\n")
    source(path, local = new.env(parent = globalenv()))
  }
  cat("\nFinal Tables 1-3 completed. See output/tables/.\n")
})
