# SHOW "=== TEST 7: BREAK Outside Loop ==="
# BREAK

# ------------------------------------------------------------
# TEST 9: ERR_DIV_BY_ZERO (5) - Division by zero
# Expected: Runtime error - divide by zero
# ------------------------------------------------------------
SHOW "=== TEST 9: Division by Zero ==="
SET a = 10
SET b = 0
SET result = a / b
SHOW result