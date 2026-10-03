extends RefCounted
## Exact fixed-point accounting: one point is 1956 units, one request 18 units.
## Recon and attack share this ledger; the UI only reads its value.

const SCALE := 1956
const LIMIT := 100 * SCALE
const REQUEST_UNITS := 18
var units := 0
var value: float:
	get:
		return float(units) / SCALE
var exhausted: bool:
	get:
		return units >= LIMIT

func charge_points(points: int) -> void:
	units = mini(LIMIT, units + maxi(0, points) * SCALE)

func charge_request() -> void:
	units = mini(LIMIT, units + REQUEST_UNITS)

static func attack_cost(count: int) -> float:
	return 0.0 if count == 0 else 2.0 + float(count * REQUEST_UNITS) / SCALE
